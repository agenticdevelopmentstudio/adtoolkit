
- **Signed-out answer vs. failure**: HTTP 200 with a `null` user → the session-fetch function resolves `null` (MUST); any non-OK status, including 401 and 403 → rejects (MUST). Signed-out is never inferred from a status code.
- **Empty or missing body field**: HTTP 200 with an empty body → resolves `null`, read as signed-out (MUST; an absent `user` field is treated the same as an explicit `null`).
- **Malformed body**: HTTP 200 with non-JSON body → rejects with the parse error; the session hook's retry behavior still applies (MUST).
- **Partial user object**: HTTP 200 with a user object carrying only `role` (no `email`, no `displayName`) → resolved unchanged (MUST, per auth-me-no-shape-validation); the header-auth hook then returns `user.name` as absent despite the shape declaring it a required string.
- **Empty display name**: `displayName: ""` → header name falls back to `email` (MUST; an empty string, not just an absent or null value, triggers the fallback).
- **Transient failure with cached session**: backend restart, proxy 500, or network blip after a successful load → cached user is kept and the fetch retried up to 3 times (MUST); the header never flashes signed-out.
- **Cold-load failure**: backend unreachable on the very first load → after four failed attempts the hook returns a `null` user with `isPending: false`, and the header shows login/signup links; see the open question on first-load-failure-projection.
- **Offline / disconnected**: the transport rejects → treated like any failure above (error kept out of `user`, retried); no offline detection of its own.
- **Timeout**: no request timeout or abort signal is set on `/auth/me` or `/auth/logout` (MUST NOT be assumed); a hung request stays pending until the platform gives up, and on first load `isPending` stays true (header spinner) for that whole time.
- **Cancellation**: the session-fetch function accepts no abort signal; the session hook's own cancellation signal is not forwarded, so an unmounted query's in-flight request is not aborted.
- **Logout failure**: logout POST returns non-OK or rejects → navigation to `/` happens anyway (MUST); on reload the session is re-read, so an un-cleared cookie shows the user still signed in. A rejection surfaces as an unhandled rejection.
- **Logout double-invoke**: calling `onLogout` twice issues two POSTs; each navigates to `/` when it settles. No guard exists.
- **Concurrent consumers**: header, board gate and landing page mounting at once share one query and one request (MUST).
- **Login without invalidation**: a login flow that sets the cookie but does not invalidate the session query key leaves the cached signed-out result in place for up to the 60,000 ms staleness window (documented caller obligation).
- **Injected client transport**: an API client built with a custom transport is honoured by `onLogout` (via the client's own request method) but not by the session hook, whose call to the session-fetch function uses the platform's default transport with only the client's URL resolution.
- **Optional DTO fields**: `phaseConfirmedAt` absent → consumers use `createdAt`; `missingEnv`, `unreachable`, `correlated` absent → treated as empty/false by consumers.

