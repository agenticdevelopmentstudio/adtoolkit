
### Auth Binding (auth.ts)

- **bearer-prefix-match**: `bearer(c)` MUST return the substring of the
  request's `Authorization` header following the literal prefix `'Bearer '`,
  trimmed of surrounding whitespace, when the header's value starts with
  that exact prefix (case-sensitive, including the trailing space).
- **bearer-absent-or-mismatched**: `bearer(c)` MUST return `undefined` when
  the `Authorization` header is absent, or is present but does not start
  with the literal prefix `'Bearer '`.
- **bearer-empty-after-trim**: When the header is exactly `'Bearer '`
  followed only by whitespace, `bearer(c)` MUST return the empty string, not
  `undefined` — a header that matches the prefix always reaches
  `.slice(7).trim()`, whose result can itself be empty.
- **require-auth-single-gate-call**: `requireAuth(gate)` MUST call
  `gate.authenticate(c.req)` exactly once per incoming request, passing
  Hono's request object directly with no adapter, and MUST await the result
  before proceeding.
- **require-auth-unauthenticated-401**: When `gate.authenticate` resolves
  `null`, `requireAuth`'s middleware MUST throw
  `HTTPException(401, { message: 'Unauthorized' })` and MUST NOT call
  `next()`.
- **require-auth-sets-three-vars**: When `gate.authenticate` resolves a
  non-null value, `requireAuth`'s middleware MUST set exactly the three Hono
  context variables `tier`, `user`, and `token` from the resolved value's
  like-named fields, then MUST call `next()`.
- **require-admin-reads-context-only**: `requireAdmin` MUST read the
  caller's tier only from the Hono context (`c.get('tier')`); it MUST NOT
  accept a gate argument, call `gate.authenticate`, or perform any
  credential resolution of its own — the source comment states it "Runs
  AFTER requireAuth."
- **require-admin-forbidden-403**: When the context's `tier` is not exactly
  the string `'admin'`, `requireAdmin` MUST throw
  `HTTPException(403, { message: 'Admin required' })` and MUST NOT call
  `next()`.
- **require-admin-admits-admin**: When the context's `tier` is exactly
  `'admin'`, `requireAdmin` MUST call `next()`.
- **require-admin-fails-closed**: Because the comparison is
  `c.get('tier') !== 'admin'`, a request on which no prior middleware set
  `tier` (an `undefined` context value) MUST be refused with `403` — the
  same outcome as an explicit non-admin tier. `requireAdmin` fails closed
  rather than admitting an unset tier.

### Rate Limiter (rate-limit.ts)

- **rate-limit-window-default**: `rateLimit(opts)` MUST use
  `opts.windowMs` as the fixed-window length in milliseconds when provided,
  and MUST default it to `60000` (60 seconds) when `opts.windowMs` is
  omitted.
- **rate-limit-key-rightmost-hop**: `rateLimit`'s per-request key
  (`clientIp`) MUST be the rightmost non-empty, trimmed entry of the
  request's `x-forwarded-for` header after splitting it on commas.
- **rate-limit-key-local-fallback**: `clientIp` MUST return the literal
  string `'local'` when the `x-forwarded-for` header is absent, or when
  splitting and trimming it yields no non-empty entries.
- **rate-limit-bucket-creation**: For a given key, `rateLimit`'s middleware
  MUST create a fresh bucket with `count: 0` and `resetAt` set to
  `now + windowMs` whenever no bucket exists for that key, or the existing
  bucket's `resetAt` is at or before the current time.
- **rate-limit-increment-before-check**: `rateLimit`'s middleware MUST
  increment the resolved bucket's `count` by exactly `1` before comparing it
  against `opts.max`, so the request that first exceeds the ceiling is
  itself counted.
- **rate-limit-block-response**: When a bucket's `count` exceeds
  `opts.max`, `rateLimit`'s middleware MUST respond `429` with the JSON body
  `{ error: { message: 'Too many attempts — try again shortly' } }` and MUST
  NOT call `next()`.
- **rate-limit-retry-after-header**: On a `429` response, `rateLimit`'s
  middleware MUST set a `Retry-After` header to the number of whole seconds
  remaining until the bucket's `resetAt`, rounded up, with a minimum value
  of `1`.
- **rate-limit-pass-through**: When a bucket's `count` is less than or
  equal to `opts.max`, `rateLimit`'s middleware MUST call `next()` and MUST
  NOT set a `Retry-After` header or otherwise alter the response.
- **rate-limit-sweep-cadence**: `rateLimit`'s middleware MUST invoke its
  sweep step only when at least `windowMs` milliseconds have elapsed since
  the previous sweep, or when the bucket map's size is at or above
  `MAX_BUCKETS` (`50_000`); it MUST NOT sweep on every request regardless of
  elapsed time or table size.
- **rate-limit-sweep-expiry**: A sweep MUST delete every bucket whose
  `resetAt` is at or before the sweep's `now`.
- **rate-limit-hard-cap-drop**: When, after deleting expired buckets, the
  map's size remains at or above `MAX_BUCKETS` (`50_000`), the sweep MUST
  log an error via `console.error` naming the live bucket count and the
  `50_000` threshold, then MUST clear the entire bucket map.
- **rate-limit-instance-isolation**: Each call to `rateLimit(opts)` MUST
  create its own independent bucket `Map` and `lastSweepAt` closure
  variable, so two middleware instances mounted on different routes (for
  example `/auth/login` and `/auth/signup`) never share a counter for the
  same client key.

### Security

`auth.ts` is where every request's tier/role decision is made, and
`rate-limit.ts` is this backend's only defense against credential-stuffing
CPU exhaustion on its unauthenticated login/signup routes; per this
cookbook's Cookbook Compliance guideline, both are security-relevant and
addressed explicitly rather than left to "platform best practices."

- **credential-value-opaque**: `bearer(c)` MUST return the raw bearer string
  unmodified except for the fixed prefix strip and a trim; it MUST NOT
  parse, decode, or validate the token's contents — token validation is the
  `AuthGate`'s job, external to these two files.
- **authorization-decision-server-side**: `requireAuth` and `requireAdmin`
  MUST derive `tier` exclusively from the `AuthGate`'s resolution and the
  Hono context variable it wrote; MUST NOT read a tier, role, or admin claim
  directly from a request header, cookie value, or query parameter.
- **no-credential-logging**: `auth.ts` and `rate-limit.ts` MUST NOT log
  the `Authorization` header's value, the resolved bearer string, or any
  other per-request credential. The one `console.error` call in
  `rate-limit.ts` logs only a live bucket count and the fixed `50_000`
  threshold, never a key, an IP, or a credential.
- **violation-outcomes-explicit**: Every rejection path in these two files
  MUST resolve to one specific, already-itemized HTTP outcome (`401` from
  `requireAuth`, `403` from `requireAdmin`, or `429` from `rateLimit`) and
  MUST NOT silently continue as though the request had passed.

Sensitive data in scope: the `Authorization` header's raw value, held only
long enough for `bearer` to strip its prefix and hand it to the caller or the
gate, and the derived `x-forwarded-for` client-IP key, held only inside a
rate-limit bucket for at most one window past its last hit. Neither file
persists, logs, or returns either value in a form that identifies a specific
requester. Storage and revocation of the underlying session/token
credentials `bearer`'s output is checked against are the `AuthGate`'s and,
beneath it, the `Storage` ports' job — external to these two files and
specified in `status-server-auth`.

