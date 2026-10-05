
### Public shape

- **hook-signature**: This logic MUST take no arguments and MUST return an object with exactly the fields `board`, `reason`, `error` and `refetch`.
- **board-field**: The returned `board` field MUST be a board object or `null`.
- **reason-field**: The returned `reason` field MUST be one of `"loading"`, `"unavailable"`, `"stale"`, `"frozen"`, `"no-data"`, or `null`.
- **reason-board-exclusive**: `reason` MUST be null exactly when `board` is non-null, and `board` MUST be null exactly when `reason` is non-null.
- **single-loading-signal**: This logic MUST NOT expose a separate loading flag; a caller wanting a spinner MUST test whether `reason` exactly equals `"loading"` (a separate loading flag would be a second way to ask one question).
- **error-field**: The returned `error` field MUST be the last fetch's error, or null when there is none.
- **refetch-field**: The returned `refetch` field MUST be a callback taking no arguments that triggers a refetch of the board and returns nothing.
- **poll-interval-export**: This logic's module MUST expose the poll interval constant (60,000 ms) alongside its main export, for callers that need the exact number.

### Fetching

- **fetch-request**: Each board read MUST issue one request for path `/board` through the API client (resolved against its base path, `/api` by default), with header `accept: application/json` and no other request options.
- **fetch-http-error**: A response whose `ok` is false MUST reject the read with an `Error` whose message is exactly `board fetch failed: <status>` (for example `board fetch failed: 500`); the response body is not read.
- **fetch-body-passthrough**: A successful response MUST be returned as the parsed JSON body, unmodified, as the board (see Platform Notes for the test asserting deep equality with the server payload).
- **fetch-parse-error**: A body that is not valid JSON MUST reject the read with the underlying parse error.
- **query-key**: The board MUST be held in a shared cache under the key `["board"]`, so every caller sharing that cache shares one cached board and one fetch.
- **poll-cadence**: This logic MUST refetch every 60 seconds while active, independent of whether the live stream is connected.
- **retry-once**: A failed read MUST be retried exactly once before an error is reported, using the underlying fetch layer's default retry delay (see Platform Notes).
- **no-timeout**: This logic MUST NOT apply its own request timeout or abort signal; a hung request stays in flight until the transport ends it or a subsequent refetch cancels it.

### Live-frame refetch

- **frame-subscription**: While active, this logic MUST subscribe to the live-frame feed and MUST call `refetch` once for every live frame delivered.
- **frame-source-agnostic**: The frame subscription MUST fire for a frame ingested by any API client's live store, because the subscriber set is shared module-wide (see Platform Notes).
- **frame-no-second-connection**: This logic MUST NOT open its own streaming connection; it piggybacks on the live snapshot's existing feed ("one connection per tab is the existing contract").
- **frame-unsubscribe**: On teardown, and before re-subscribing when the `refetch` function's identity changes, this logic MUST remove its frame subscriber.
- **frame-no-throttle**: This logic MUST NOT debounce or coalesce frames; each frame calls `refetch`, cancelling any in-flight board read in favor of the new one (see Platform Notes).

### Availability verdict

The verdict is computed every time this logic runs, from the cached data (the last successful board, retained across later failures) and the current time. The branches are evaluated in this order and the first match wins:

- **verdict-loading**: When there is no cached board and the initial load is still in flight (pending and fetching), `reason` MUST be `"loading"`.
- **verdict-unavailable**: When there is no cached board and the initial load has already finished (the fetch failed after its retry, or the fetch is paused), `reason` MUST be `"unavailable"`.
- **verdict-stale**: When a cached board exists and its read clock is judged stale against the current time, `reason` MUST be `"stale"`.
- **stale-threshold**: The staleness check MUST return true when the current time minus the parsed `generatedAt` timestamp is greater than 180,000 ms (three poll cycles), and false when it is less than or equal.
- **stale-unparseable-clock**: The staleness check MUST return true (fail closed) when `generatedAt` does not parse to a finite age.
- **stale-client-clock**: The read-clock check MUST be judged against the client's wall clock as sampled at its default 30-second refresh, so a board is reported stale no later than about 30 seconds after it crosses the 180,000 ms threshold.
- **verdict-no-data**: When the board is not stale and `board.dataAsOfMs` is null, `reason` MUST be `"no-data"`.
- **verdict-frozen**: When the board is not stale and the data-clock freshness check on `dataAsOfMs`, `generatedAt` and `probeIntervalMs` returns `"frozen"`, `reason` MUST be `"frozen"`.
- **frozen-threshold**: The data clock MUST read `"frozen"` when the parsed `generatedAt` timestamp minus `dataAsOfMs` is greater than the data-staleness window for `probeIntervalMs`, which equals `max(probeIntervalMs × 5, 300000) × 2` ms (600,000 ms at the default 60-second cadence).
- **frozen-unparseable-lag**: The data clock MUST read `"frozen"` when the lag between `generatedAt` and `dataAsOfMs` is not a finite number.
- **frozen-server-clock**: The data-clock check MUST compare two server timestamps carried on the board being judged (`generatedAt` and `dataAsOfMs`), using the cadence carried on that same board (`probeIntervalMs`), and MUST NOT depend on the client clock or on the live snapshot.
- **verdict-current**: When the board is not stale and its data clock reads `"current"`, `reason` MUST be null and `board` MUST be the cached board object, unmodified.
- **stale-over-frozen**: When a board is both stale and frozen, `reason` MUST be `"stale"`, because the read-clock check is evaluated first.
- **error-independent-of-board**: `error` MUST reflect the last fetch's error state independently of the verdict, so a board that is still current from an earlier successful read MAY be returned alongside a non-null `error` from a later failed poll.
- **retained-data-ages-out**: A board retained from an earlier success while later polls fail MUST keep being judged each time this logic runs, and MUST become `board: null, reason: "stale"` once its `generatedAt` crosses the 180,000 ms threshold.

### State and persistence

- **no-durable-state**: This logic MUST NOT write to durable client storage of any kind (see Platform Notes for the test asserting nothing is written); the only board storage is an in-memory cache.
- **server-removal-propagates**: A problem absent from the next server read MUST be absent from the returned board after that read, with no client-side accumulation.
- **no-derivation**: This logic MUST NOT derive, merge or filter board contents; all content derivation belongs to the server.
- **render-thread**: All verdict computation MUST run synchronously each time this logic runs, without interleaving; the live-frame callback, the poll timer and the clock-refresh interval MUST only schedule state updates, never running concurrently with the computation itself (see Platform Notes).
- **response-shape-precondition**: This logic MUST treat the response body's conformance to the board shape as a caller precondition: the body is cast, not validated (see Platform Notes for how the shape is kept in step with the server's type).

