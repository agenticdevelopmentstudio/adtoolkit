
- **First load in flight**: The state MUST return `null`, the same value as signed out (use-status-user-006). Callers that must not flash signed-out UI MUST use the shared session state's loading flag instead.
- **First load fails with nothing cached**: After 4 failed attempts the state MUST return `null`. This is "unknown", and a later refetch trigger (focus, reconnect or remount) retries the load (use-status-user-008).
- **Transient failure while signed in**: The state MUST keep returning the cached user (use-status-user-007). A 5xx from the proxy, a deploy restart or a network blip MUST NOT sign the user out.
- **Backend returns 401 or 403**: This is treated like any other non-OK status. The request function MUST throw, and the cached session MUST be kept. The source relies on the backend never sending 401 on this route, so this client has no path that turns an auth error into a sign-out.
- **OK response with a non-JSON body**: Parsing the body as JSON rejects, and the read MUST treat the rejection as a failure: it is retried and the cached session is kept.
- **OK response missing `user`**: The state MUST resolve to `null` (use-status-user-011).
- **Unexpected `role` or missing `email`**: The state MUST pass the value through unchanged (use-status-user-013). Role-gated callers then compare against the known values, so an unknown role matches neither `"admin"` nor `"viewer"`.
- **Sign-in without invalidation**: If a login flow sets the cookie but does not invalidate the `status-auth-me` cache entry, the state MUST keep returning the cached `null` until the 60,000 ms fresh window ends and a refetch trigger fires.
- **Sign-out**: The logout action sends a `POST` to `/auth/logout` and then performs a full page navigation to `/`. That reload discards the cache, so the next load MUST return `null`. This state itself never clears the cache.
- **Concurrent consumers**: Several consumers mounting at the same moment MUST share one request through the single key (use-status-user-009).
- **Offline**: While disconnected, a failed request is retried and the cached session is kept. After reconnecting, the platform's reconnect trigger MUST refetch a stale session.
- **No timeout or cancellation**: The request function passes no cancellation signal and sets no timeout. A hung request stays pending until the platform's network stack gives up, and the state keeps returning its current value meanwhile.

