
### Session Cookie (cookie.ts)

- **session-cookie-name**: `setSessionCookie`, `clearSessionCookie`, and
  `readSessionCookie` MUST all operate on the cookie named `status_auth`
  (`SESSION_COOKIE`).
- **session-cookie-http-only**: `setSessionCookie` MUST set `httpOnly: true`
  on the session cookie.
- **session-cookie-same-site-lax**: `setSessionCookie` MUST set
  `sameSite: 'Lax'` on the session cookie, per the source comment, so the
  GitHub OAuth redirect back to `/home` still carries it.
- **session-cookie-secure-flag-from-config**: `setSessionCookie` MUST set the
  cookie's `secure` flag to the caller-supplied `config.cookieSecure` value,
  never a hardcoded constant, deferring the http-vs-https decision to the
  host.
- **session-cookie-path-root**: `setSessionCookie` and `clearSessionCookie`
  MUST scope the cookie to `path: '/'`.
- **session-cookie-max-age**: `setSessionCookie` MUST set `maxAge` to
  2,592,000 seconds (30 days), traced to `MAX_AGE_SECONDS = 30 * 24 * 60 * 60`.
- **session-cookie-clear**: `clearSessionCookie` MUST delete the
  `status_auth` cookie at `path: '/'`.
- **session-cookie-read-returns-undefined**: `readSessionCookie` MUST return
  `undefined` (not throw) when no `status_auth` cookie is present on the
  request.

### Default Auth Gate (default-adapter.ts)

- **auth-disabled-short-circuit**: When `config.authDisabled` is `true`,
  `authenticate` MUST resolve immediately to
  `{ tier: 'admin', user: null, token: null }` without evaluating the
  session, bearer-token, or peer-token checks.
- **session-checked-first**: `authenticate` MUST resolve the request's
  session cookie (via `storage.auth.resolveSession`) before attempting the
  bearer-token or peer-token checks, so a request carrying both a valid
  session cookie and an `Authorization` header authenticates from the
  cookie.
- **session-role-gate**: When `storage.auth.resolveSession` resolves a user
  whose `role` is `admin` or `viewer`, `authenticate` MUST resolve to
  `{ tier: 'admin' | 'view', user, token: null }` (`admin` role maps to tier
  `admin`, `viewer` role maps to tier `view`). MUST NOT resolve any tier for
  a `pending` role or any other role value; such a request falls through to
  the bearer-token check exactly as if no session existed.
- **bearer-token-prefix-gate**: `authenticate` MUST attempt an API-token
  lookup (`storage.tokens.validateApiToken`) only when the request's
  `Authorization: Bearer` value starts with the literal prefix `sts_`; MUST
  NOT call `validateApiToken` for a bearer value with any other prefix
  (including an absent header or an empty string).
- **bearer-token-role-mapping**: When `validateApiToken` resolves a token,
  `authenticate` MUST resolve to `{ tier: 'admin' | 'view', user: null, token }`,
  mapping the token's `role: 'admin'` to tier `admin` and `role: 'user'` to
  tier `view`.
- **bearer-token-invalid-terminal**: When a bearer value starts with `sts_`
  but `validateApiToken` resolves `null` (unknown, revoked, or expired),
  `authenticate` MUST resolve to `null` immediately; MUST NOT fall through
  to the peer-token check.
- **peer-token-path-restricted**: `authenticate` MUST grant the peer-token
  bearer only when the request path is exactly `/snapshot`; MUST NOT accept
  a matching `PEER_TOKEN` bearer on any other path.
- **peer-token-requires-config**: `authenticate` MUST NOT accept a
  peer-token bearer when `config.peerToken` is the empty string, regardless
  of the bearer value presented.
- **peer-token-constant-time-compare**: `authenticate` MUST compare the
  request's bearer value against `config.peerToken` with `timingSafeEqual`
  over two `Buffer`s of equal length, and MUST treat unequal-length buffers
  as a non-match without invoking `timingSafeEqual` on them
  (`safeEqual`'s `ab.length === bb.length && timingSafeEqual(ab, bb)`).
- **peer-token-tier**: A successful peer-token match MUST resolve to
  `{ tier: 'view', user: null, token: null }` — never tier `admin`.
- **unauthenticated-terminal-null**: When AUTH_DISABLED is off and the
  session, bearer-token, and peer-token checks all fail to resolve a
  caller, `authenticate` MUST resolve to `null`.
- **gate-never-throws**: `authenticate` MUST NOT throw for an
  unauthenticated or rejected caller; every non-matching branch resolves to
  `null` rather than raising.

### GitHub OAuth (github.ts)

- **github-start-requires-config**: `GET /auth/github/start` MUST respond
  `500` with message `'GitHub login is not configured'` when
  `config.github.clientId` or `config.publicBaseUrl` is empty, before
  generating any state or redirecting.
- **github-start-state-generation**: `GET /auth/github/start` MUST generate
  a fresh 16-byte random value, hex-encoded, as the OAuth `state` for every
  request (`randomBytes(16).toString('hex')`).
- **github-start-state-cookie**: `GET /auth/github/start` MUST store the
  generated state in a cookie named `gh_oauth_state`
  (`httpOnly: true`, `path: '/'`, `maxAge: 600`, `sameSite: 'Lax'`, `secure`
  from `config.cookieSecure`).
- **github-start-redirect**: `GET /auth/github/start` MUST redirect (`302`)
  to `https://github.com/login/oauth/authorize` with query parameters
  `client_id`, `redirect_uri` set to
  `${config.publicBaseUrl}/api/auth/github/callback`, `scope` set to
  `read:user user:email`, the generated `state`, and `allow_signup=true`.
- **github-callback-state-validated**: `GET /auth/github/callback` MUST
  respond `400` with message `'Invalid OAuth state'` when the request is
  missing the `code` query param, missing the `state` query param, missing
  the `gh_oauth_state` cookie, or when the query `state` does not exactly
  equal the cookie's value.
- **github-callback-state-cookie-cleared**: `GET /auth/github/callback`
  MUST delete the `gh_oauth_state` cookie unconditionally, before
  validating state, so the state cookie can never be reused across two
  callback requests.
- **github-fetch-timeout**: Every GitHub API call `exchangeCode` issues via
  `ghFetch` MUST carry a deadline of `config.github.fetchTimeoutMs`
  milliseconds when set, defaulting to `8000`, via
  `AbortSignal.timeout(...)`.
- **github-fetch-unreachable-maps-502**: When a GitHub fetch throws (a
  network failure, or an abort from the deadline above), `ghFetch` MUST
  respond `502` with message `'GitHub is unreachable'`.
- **github-token-exchange-failure-502**: `exchangeCode` MUST respond `502`
  with message `'GitHub token exchange failed'` when the access-token
  exchange response is not `ok`.
- **github-token-exchange-missing-token-401**: `exchangeCode` MUST respond
  `401` with message `'GitHub authorization failed'` when the token-exchange
  response is `ok` but its parsed body carries no `access_token`.
- **github-profile-fetch-failure-502**: `exchangeCode` MUST check the
  `GET /user` response's `ok` status before parsing its body, and MUST
  respond `502` with message `'Could not read the GitHub profile'` when it
  is not `ok`.
- **github-profile-missing-id-502**: `exchangeCode` MUST respond `502` with
  message `'GitHub profile is missing an id'` when the parsed profile's `id`
  is not a finite number.
- **github-email-fallback**: When the `GET /user` profile's `email` is
  falsy, `exchangeCode` MUST fetch `GET /user/emails` and adopt the first
  entry whose `primary` and `verified` are both `true`; when no such entry
  exists, or the `/user/emails` fetch is not `ok`, the resolved email MUST
  be `null`.
- **github-email-lowercased**: `exchangeCode` MUST lower-case a non-null
  resolved email before returning it.
- **github-display-name-fallback**: `exchangeCode` MUST set `displayName`
  to the profile's `name` when it is truthy, else the profile's `login`,
  else the literal string `'GitHub user'`.
- **github-callback-links-existing-email**: When no `UserRecord` matches the
  GitHub id and a resolved email matches an existing user, the callback MUST
  attach the GitHub id to that existing user (`attachGithubId`) rather than
  creating a second account for the same email.
- **github-callback-creates-new-user**: When no `UserRecord` matches the
  GitHub id and (no email was resolved, or the resolved email matches no
  existing user), the callback MUST create a new user whose `email`
  defaults to `` gh_<githubId>@users.noreply.github.com `` when the GitHub
  profile carries no email, whose `role` is `roleForEmail(email, config)`
  when an email was resolved and `'pending'` otherwise, and whose
  `githubId` is the GitHub profile's id.
- **github-callback-race-recovers**: When the `createUser`/`attachGithubId`
  call rejects with a unique-constraint violation (a concurrent first login
  racing for the same identity), the callback MUST recover by re-resolving
  the user via `findUserByGithubId`, then `findUserByEmail` when that
  misses, and MUST re-throw the original error only when neither resolves a
  user.
- **github-callback-sets-session-and-redirects**: On success, the callback
  MUST create a session for the resolved user (`storage.auth.createSession`),
  set it as the `status_auth` cookie via `setSessionCookie`, and redirect
  (`302`) to `/home`.

### Password Hashing (password.ts)

- **password-hash-cost**: `hashPassword` MUST hash with bcrypt cost factor
  10 (`COST = 10`), stated in the source comment to match the main backend's
  bcrypt cost.
- **password-hash-async**: `hashPassword` MUST return a `Promise<string>`
  produced by bcrypt's asynchronous `hash`, not a synchronous call.
- **password-verify**: `verifyPassword` MUST resolve to exactly the boolean
  `bcrypt.compare(plain, hash)` resolves to — `true` only on a matching
  plaintext/hash pair, `false` for every mismatch, including a malformed
  `hash` (which `bcrypt.compare` resolves `false` for rather than
  rejecting).
- **dummy-hash-precomputed**: The module MUST export `DUMMY_PASSWORD_HASH`,
  a real cost-10 bcrypt hash of the fixed string `'login-timing-equalizer'`,
  computed once at module load via `bcrypt.hashSync`, for a caller to
  compare against when no matching user or password hash exists, so a login
  response's timing does not reveal whether an email is registered.
  Consuming this value in a constant-effort login comparison is the login
  route's responsibility — external to this source, which only supplies the
  precomputed hash.

### Auth Gate Contract (port.ts)

- **auth-request-shape**: An `AuthRequest` MUST expose a readonly
  `path: string` and a `header(name: string): string | undefined` method;
  Hono's `c.req` satisfies this directly, so a Hono host constructs no
  adapter.
- **auth-vars-shape**: An `AuthVars` value MUST carry exactly three fields:
  `tier: 'view' | 'admin'`, `user: AuthUser | null`, and
  `token: TokenPrincipal | null`.
- **auth-gate-contract-never-throws-for-unauthenticated**: Per the
  `AuthGate` interface's doc comment, an implementation MUST resolve to
  `null` for an unauthenticated or rejected caller and MUST NOT throw or
  encode an HTTP status itself; translating a `null` resolution into a
  `401` is the Hono binding's job (`../middleware/auth`, external to this
  source).
- **auth-gate-host-swappable**: `AuthGate` MUST be implementable with no
  dependency on this package's `Storage` or `StatusConfig` types, so a host
  can substitute its own session store or SSO check without the HTTP layer
  above it changing.

### Security

This module is where every credential the status backend accepts — a
session cookie, an `sts_` API bearer token, the machine `PEER_TOKEN`, a
GitHub OAuth code, and a user's password — is resolved or minted. It is a
security-relevant recipe per this cookbook's Cookbook Compliance guideline,
so the concerns below are addressed explicitly rather than left to "platform
best practices."

- **session-token-opaque**: `cookie.ts`, `default-adapter.ts`, and
  `github.ts` MUST treat the session token carried in the `status_auth`
  cookie as an opaque string; none of them decodes, parses, or derives
  meaning from its bytes — its meaning is resolved entirely by
  `storage.auth.resolveSession`, external to these five files and not
  specified here.
- **credential-never-logged**: The functions in these five files MUST NOT log a
  raw bearer value, `PEER_TOKEN`, GitHub OAuth `client_secret`, GitHub
  access token, or password. `exchangeCode` holds the GitHub access token
  only in a local variable used to build two outbound request headers; none
  of these files contains a logging call of any kind (see Logging).
- **oauth-state-single-use**: Because `github-callback-state-cookie-cleared`
  deletes `gh_oauth_state` on the very first callback request that reads
  it, a replayed callback presenting the same `state` value MUST fail
  `github-callback-state-validated` on every request after the first,
  unless a fresh `/auth/github/start` reissued a matching cookie.
- **violation-resolves-to-an-explicit-outcome**: Every credential-rejection
  path in these five files MUST resolve to one specific, already-itemized
  outcome — `authenticate` resolving to `null` (unauthenticated-terminal-null,
  bearer-token-invalid-terminal), or one of the named `HTTPException`
  statuses in `github.ts` (`400`, `401`, `500`, `502`) — and MUST NOT
  silently continue as if the caller had succeeded.

Sensitive data in scope: the session token (opaque, cookie-only,
`httpOnly`), the `sts_` API bearer token (opaque, `Authorization` header
only), the `PEER_TOKEN` shared secret, the GitHub OAuth `client_secret` and
exchanged access token (server-side only, per `exchangeCode`'s doc comment:
"the secret never touches the browser"), and the user's password (bcrypt
hash only; the plaintext exists only for the duration of one
`hashPassword`/`verifyPassword` call). Storage of the password hash,
session-token hash, and API-token hash is the `AuthStore`/`TokenStore`
ports' job, external to these files; what these files guarantee is that
they never persist, log, or return a plaintext password or raw token
themselves. Transmission: the session cookie is `httpOnly` always and
`Secure` whenever `config.cookieSecure` is true (a host opts out only for
local/e2e http per `cookie.ts`'s comment); GitHub API calls are made to
hardcoded `https://` origins. Revocation of a session or API token
(`revokeSession`, `revokeApiToken`) is likewise the `Storage` ports' job,
called from outside these five files.

