
- **zero-or-negative-days**: Calling this state with `0` or a negative value MUST still fetch, sending `days=0` or `days=-5` as-is. The backend `/uptime` route owns the response: it maps `0` or an unparsable value to its default of 90, and clamps the result to 1–365, so `-5` becomes `1`; the state surfaces whatever arrives.
- **fractional-days**: Calling this state with `1.5` MUST send `days=1.5` and cache under a key holding `1.5`; the backend reads it as `1`, so the response `days` field is `1` while the cache key holds `1.5`.
- **non-finite-days**: `NaN` or `Infinity` MUST be sent as the literal text `days=NaN` or `days=Infinity` and cached under a key holding that value; the state performs no numeric validation, and both known consumers pass the constant `90`.
- **large-window**: A `days` value above 365 MUST be sent unchanged; the backend clamps it to 365, and the state does not compare the requested and returned `days`.
- **days-mismatch**: If the backend's `days` field differs from the requested value, the state MUST return the body unchanged.
- **empty-services**: A successful response with `services: []` MUST resolve as data; the state applies no emptiness check (the portfolio percentage then yields `null`).
- **null-percentages**: A service or day whose `uptimePercent` is `null` (the backend's value when a service has zero checks) MUST resolve unchanged; the state does not fill or drop it.
- **malformed-body**: A body that is valid JSON but not shaped like the uptime response (for example missing `services`) MUST resolve as data unchanged; the state performs no shape validation, and both known consumers guard by defaulting a missing services list to an empty one.
- **204-response**: A `204 No Content` response is `ok`, so the state MUST attempt to parse the empty body as JSON, which rejects and puts the read in its error state.
- **server-error**: A non-2xx status, including the `401` the route's OpenAPI entry documents, MUST produce an error with the message `uptime <status>`; retries follow the host cache's policy (the platform's library default is 3 retries with exponential backoff when the host sets none).
- **unreachable-server**: A rejected request MUST surface as the read's error with no state-level retry, fallback data, or message rewriting; with no polling, the read stays in error until a default platform trigger or a manual refetch runs it again.
- **error-after-success**: When a refetch fails after an earlier success, the platform MUST keep the previous `data` alongside the new `error`, so callers keep showing the last good uptime.
- **hung-request**: With no timeout or cancellation signal from the state, a request that never settles MUST leave the read in its fetching state indefinitely.
- **days-change-mid-flight**: When `days` changes while a request is in flight, the new window MUST get its own cache entry and request; the earlier request resolves into its own key and does not overwrite the new window's data.
- **stale-data**: Because the state sets no polling interval, uptime shown on a dashboard left open and focused MUST stay at the first-loaded values until a refocus, reconnect, remount, or manual refetch triggers a new fetch.
- **unmount**: When the last consumer using a given `days` unmounts, the cached result MUST remain until the host cache's garbage-collection time elapses.

