
- **Classification pending**: While the classification query has not resolved, `status` MUST be `EMPTY_STATUS` even though the endpoint axis could be computed from loaded rosters; `isLoading` is `false` and `error` is not set, so the result gives no signal distinguishing "classification still loading" from "zero gaps" (MUST, as implemented).
- **Classification failed**: `status` MUST stay `EMPTY_STATUS` (both axes zero) while `error` carries the failure and `configure` stays populated (MUST).
- **Roster failed, classification succeeded**: `configure` is not available, `status` is `EMPTY_STATUS`, and `error` is the roster error (MUST).
- **Both failed**: Only the roster error is returned in `error`; the classification error is dropped from this result but remains on its own cached query (MUST).
- **Empty rosters**: Four empty arrays with a loaded classification MUST yield `unconfiguredSites: []` and `counts.sites: 0`; project counts still come from the server (MUST).
- **Empty classification**: `pending`, `addable` and `noDomain` all empty MUST yield `counts.projects: 0`, `noDomainProjects: 0` and an empty `unmonitoredByPlatform` map (MUST).
- **Null or unknown platform on a pending project**: `null` MUST tally under the key `""`; an unrecognized string MUST tally under itself unchanged (MUST).
- **Malformed server body**: The classification response is trusted, not validated; a body missing `pending` or `noDomain` makes status assembly fail when it reads `.length` or iterates. This is a fact of the current implementation; the response shape is owned by the backend route `GET /deploy-projects/unconfigured` (MUST, as implemented).
- **Disabled consumer with warm cache**: With `enabled: false` and another enabled consumer having populated both keys, this consumer MUST return the full model from cache (MUST).
- **Concurrent readers**: Ordering guarantees hold within a single execution thread; concurrent readers share one in-flight query per key through the cache's own deduplication, so there is no interleaving to order (MUST).
- **Offline / unreachable server**: Each failing read fails its own query and surfaces through `error` per the precedence rule; Config Status adds no retry or timeout of its own (MUST).
- **Cancellation**: Config Status does not cancel in-flight reads on unmount or on disable; cancellation, if any, is the shared cache's own behavior (MUST, as implemented).

