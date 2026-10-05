
### Named configuration

- **poll-interval-export**: Live Snapshot MUST define a named interval constant, `POLL_INTERVAL_MS`, with the value 60,000.
- **same-snapshot-null**: The same-snapshot check MUST return false when the first snapshot compared is null.
- **same-snapshot-identity**: The same-snapshot check MUST return true when the two snapshots compared are the same object.
- **same-snapshot-clock**: The same-snapshot check MUST return true when the two snapshots are distinct objects with equal `generatedAt` strings, and false when their `generatedAt` strings differ.
- **frame-subscribe**: Frame subscription MUST add a callback to a shared subscriber set and MUST return a function that removes it.
- **frame-subscribers-module-wide**: The frame subscriber set MUST be shared by every store, so a subscriber is called for a snapshot ingested by any client's store.
- **frame-not-connection-state**: Frame subscribers MUST be called only when a snapshot is ingested, never on a connection-state change (stream open, error, schedule notification).
- **test-reset**: The test-reset operation MUST reset every store and then empty the store registry.
- **test-reset-keeps-frames**: The test-reset operation MUST NOT clear the frame subscriber set, because clearing it would silently unsubscribe a mounted board state.

### Store registry

- **store-per-client**: Every use of Live Snapshot MUST resolve its store by the identity of the client returned from the app's API context, creating the store on first use and reusing it afterward.
- **store-client-fixed**: A store MUST talk only through the client it was constructed with; the client is never reassigned later.
- **store-lookup-before-subscribe**: Live Snapshot MUST resolve its store before subscribing, because subscribing may open the stream in the same step.
- **fresh-view**: A new store's view MUST be `{ snapshot: null, streamConnected: false, nextCheckAt: null, awaitingCheck: false, liveError: null }`.
- **server-view-stable**: A store's server-rendering view MUST return the initial view object for the store's whole life, so a universal-rendering pass and the first client paint match.
- **patch-no-op**: A view update whose every field is strictly equal to the current value MUST NOT replace the view object or notify listeners.
- **patch-copy**: A view update that changes any field MUST replace the view with a new object and notify every listener once.

### Stream lifecycle

- **stream-ref-count**: Each store subscription MUST increment a stream reference count and open the stream connection; each unsubscribe MUST decrement it.
- **stream-single**: A store MUST hold at most one open stream connection; opening while one exists MUST do nothing.
- **stream-no-window**: The store MUST NOT open a stream connection when no live client execution environment for streaming is available (during server rendering).
- **stream-path**: The stream connection MUST be opened by asking the client for a stream connection to `/live/stream`, which resolves to `/api/live/stream` with the default client.
- **stream-open-event**: The stream connection becoming open MUST set `streamConnected` to true.
- **stream-transient-error**: A transient connection error (one that leaves the connection not permanently closed) MUST set `streamConnected` to false and MUST NOT close or recreate the connection; the underlying transport auto-retries.
- **stream-closed-error**: A terminal connection error (one that leaves the connection permanently closed) MUST close the connection, drop it from the store, and set `streamConnected` to false and `nextCheckAt` to null.
- **stream-reopen**: After a terminal connection error the store MUST open a new connection `STREAM_REOPEN_MS` (3,000 ms) later, provided the reference count is still above zero at that moment.
- **stream-reopen-single**: A reopen MUST NOT be scheduled while one is already pending or while the reference count is zero or less.
- **stream-release**: When the reference count drops to zero or below it MUST be clamped to zero, any pending reopen cancelled, the connection closed and dropped, and `streamConnected` set to false and `nextCheckAt` to null.

### Notifications and ingestion

- **snapshot-frame**: A snapshot notification's payload MUST be parsed as JSON and ingested as a `LiveSnapshot`.
- **snapshot-frame-malformed**: A snapshot notification whose payload fails to parse MUST be dropped without changing the view or raising an error (the next notification, or the poll fallback, recovers).
- **schedule-frame**: A schedule notification's payload MUST be parsed as an object with a `nextCheckAt` field (a date string or null), and MUST set `nextCheckAt` to that value's parsed timestamp when present, and to null otherwise.
- **schedule-frame-malformed**: A schedule notification whose payload fails to parse MUST be ignored, leaving `nextCheckAt` unchanged.
- **ingest-once**: Snapshot ingestion MUST do nothing when the incoming snapshot is the same as the last ingested one, under the same-snapshot check.
- **ingest-update**: Otherwise, ingestion MUST record the incoming snapshot as last ingested, set the view's `snapshot` to it, and then notify every frame subscriber once.
- **ingest-shape-precondition**: Snapshot bodies from the stream and the poll MUST be treated as conforming to `LiveSnapshot` by precondition — assumed rather than verified at runtime.
- **poll-ingest**: Every non-empty poll result MUST be passed through snapshot ingestion, so a poll result and a stream push for the same cycle are folded into one update.

### Poll fallback

- **poll-query-key**: The poll MUST be cached under the key `["live"]`, reading through the store's live-read operation.
- **poll-interval**: The poll MUST refetch every `POLL_INTERVAL_MS` while `streamConnected` is false and MUST NOT refetch on an interval while it is true.
- **poll-auto-triggers**: Refresh on returning focus, on first use, and on network reconnection MUST be enabled exactly when `streamConnected` is false.
- **poll-retry**: A failed poll MUST be retried once before the query reports an error.
- **fetch-request**: The live read MUST issue a request to `/live` with no added options.
- **fetch-http-error**: A response that is not successful MUST fail with an error whose message is `live <status>` (for example `live 503`).
- **fetch-success-clears-error**: A successful read MUST set `liveError` to null and resolve with the parsed body.
- **fetch-failure-sets-error**: A failed read (an unsuccessful response, a network failure, or a parse failure) MUST set `liveError` to that failure's message text and propagate the failure.
- **live-error-sticky**: `liveError` MUST change only on a completed read, so it stays set across in-flight refetches until a read succeeds.
- **stream-loss-refetch**: Whenever `streamConnected` is false after Live Snapshot's state is re-evaluated (including the first time), it MUST trigger a re-read of the live cache key.
- **per-client-poll-isolation**: Each store SHOULD have its own transport and poll. The poll cache key is the same for every client, so two stores under one query client share one cache entry: one client's poll result is ingested into both stores, and the live error is recorded only in the store whose fetch ran.

### Manual check

- **check-start**: The manual check operation MUST cancel any pending check safety timer, record the current time as the check's request time, set `awaitingCheck` to true, and send a POST request to `/live/check`.
- **check-post-sync**: The request MUST be issued synchronously within the manual check operation, before any other asynchronous step.
- **check-no-idempotency**: Each manual check MUST send one POST with no body and no idempotency key; debouncing and coalescing are the backend route's behavior, reported back as `ran: false`.
- **check-ran**: The check MUST count as started when the response is OK and its JSON body does not have `ran` strictly equal to false (a missing or unparseable body counts as started).
- **check-not-ran**: When the response is not OK, the request fails, or the body has `ran: false`, the store MUST clear the request time and set `awaitingCheck` to false.
- **check-not-ran-refetch**: In the not-started case the store MUST call the poll re-read only when `streamConnected` is false.
- **check-started-no-refetch**: In the started case the store MUST NOT re-read `/live` immediately; it MUST wait for the cycle's snapshot.
- **check-resolve**: An ingested snapshot MUST clear `awaitingCheck` and the safety timer only when a check is pending and the snapshot's `generatedAt` timestamp is greater than or equal to the check's request time.
- **check-unrelated-push**: An ingested snapshot with a `generatedAt` before the check's request time MUST update `snapshot` but MUST leave `awaitingCheck` true.
- **check-safety**: In the started case, if no resolving snapshot arrives within `CHECK_SAFETY_MS` (200,000 ms), the store MUST clear the request time, set `awaitingCheck` to false, and call the poll re-read once.
- **check-no-error-surface**: A failed check MUST NOT set `liveError` or expose any error; it is indistinguishable to the caller from a debounced check.
- **overlapping-check-requests**: A refresh MAY be called while an earlier check request is still in flight; no ordering rule applies. A call clears any existing safety timer when it starts, but assigns its own timer only after its request resolves, without clearing a timer already assigned. When the first call finishes without a started cycle (debounced, coalesced or failed), it clears the awaiting-check flag and request time that belong to the second call. When both calls start a cycle, the second-resolving call overwrites the timer handle while the first timer stays armed and uncancellable, so it can clear the later check's spinner; only the last-assigned timer is cancelled on resolve or reset.

### Reconnect

- **reconnect-read**: The reconnect operation MUST trigger a re-read of the live cache key and MUST NOT send a POST to `/live/check`.
- **reconnect-stable**: The reconnect operation MUST keep a stable identity while the shared cache context is unchanged, and the manual check operation MUST keep a stable identity while the store and reconnect operation are unchanged.

### Returned value

- **result-shape**: Live Snapshot MUST take no arguments and return a result with exactly the fields `snapshot`, `offline`, `disconnected`, `blind`, `offlineDetail`, `polling`, `nextPollAt`, `refresh` and `reconnect`.
- **result-snapshot**: `snapshot` MUST be the store view's last ingested snapshot, or null before any ingestion.
- **result-offline**: `offline` MUST be true exactly when `liveError` is non-null, `streamConnected` is false, and the poll read is not in flight.
- **result-disconnected**: `disconnected` MUST be true exactly when `liveError` is non-null and `streamConnected` is false, regardless of whether a read is in flight.
- **result-blind**: `blind` MUST be true exactly when `snapshot` is non-null and `snapshot.services` is empty.
- **result-offline-detail**: `offlineDetail` MUST equal `liveError` when `disconnected` is true and null otherwise.
- **result-polling**: `polling` MUST be true when a poll read is in flight or `awaitingCheck` is true.
- **result-next-poll-streaming**: While `streamConnected` is true, `nextPollAt` MUST be `nextCheckAt` when it is non-null, and the client estimate otherwise.
- **result-next-poll-fallback**: While `streamConnected` is false, `nextPollAt` MUST be the client estimate.
- **client-estimate**: The client estimate MUST be the poll's last successful read time plus `POLL_INTERVAL_MS` when that time is known, and null otherwise.

### Threading, persistence, side effects

- **single-thread**: All store mutation MUST run on a single execution thread, from event callbacks, timers and asynchronous continuations; store code cannot interleave with itself.
- **no-persistence**: Live Snapshot MUST NOT persist any of its state to durable storage; all state is in memory for as long as the app runs, and is lost on reload.
- **no-timeout**: The live read and the check request MUST NOT apply a client request timeout or cancellation signal; only the check's safety timer bounds the spinner.
- **side-effects**: The only network side effects MUST be the stream connection to `/live/stream`, a GET to `/live`, and a POST to `/live/check`, all through the injected client.
- **client-only**: Live Snapshot MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

