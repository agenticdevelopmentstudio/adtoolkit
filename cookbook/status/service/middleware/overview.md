
This is the status backend's HTTP binding layer: two files under
`src/middleware/` that sit between Hono's router and the rest of the app.
`auth.ts` exports `bearer` (a small `Authorization`-header helper),
`requireAuth` (a factory that turns any host-supplied `AuthGate`'s
resolution — the `tier`/`user`/`token` triple defined in `../auth/port` and
documented in the sibling `status-server-auth` recipe — into a `401` or a
populated Hono context) and `requireAdmin` (a fixed, gate-less per-route
guard that demands `tier === 'admin'` from whatever `requireAuth` already
set). `rate-limit.ts` exports `rateLimit`, a fixed-window, per-key request
ceiling built for the PRE-AUTH surface — `/auth/login` and `/auth/signup` —
where, per the source comment, every attempt costs a bcrypt verification on
the API thread, so with no ceiling credential stuffing doubles as a CPU
attack.

All authentication MECHANISM — session lookup, bearer-token validation, the
`PEER_TOKEN`/`AUTH_DISABLED` paths — lives in the `AuthGate` implementation
these files receive as a parameter (the default one, `../auth/default-adapter`,
is documented in `status-server-auth`); this recipe's two files never resolve
a credential themselves. `auth.ts` only translates a gate's resolution into
HTTP, and `rate-limit.ts` independently caps request volume by client key,
with no knowledge of what a request is trying to do.

