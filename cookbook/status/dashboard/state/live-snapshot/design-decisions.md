
**Decision**: Keep one store per API client in a shared registry instead of per-view state.
**Rationale**: Live Snapshot is used by several views; per-view state would fork the store and open one connection each. Keying by client identity lets a host with two backends get two stores (module header comment).
**Approved**: pending

**Decision**: Treat the server-push stream as the primary feed and gate every poll trigger off while it is connected.
**Rationale**: The backend pushes on every cycle and webhook; polling alongside it is redundant work. Idempotent ingestion makes a stray poll harmless (comment on the poll's read step).
**Approved**: pending

**Decision**: Recreate the stream connection after a terminal connection error, but not after a transient one.
**Rationale**: The underlying transport auto-retries network drops but never a non-200 connect (auth expiry, 5xx); without the recreate the tab is "stuck on the poll forever". This decision is specific to platforms whose streaming transport does not itself distinguish and auto-retry these two cases (the web platform's `EventSource`); a platform-native implementation should keep the same two-case distinction.
**Approved**: pending

**Decision**: Own `liveError` in the store instead of reading the shared cache's own error flag.
**Rationale**: On a cold board the shared cache resets to pending at each refetch, so an error flag held too briefly for the reconnect overlay's 1.2 s show delay and the board sat on "Loading…" through a redeploy (doc comment on `liveError`).
**Approved**: pending

**Decision**: Expose both `offline` (drops during an in-flight read) and `disconnected` (stable across reads).
**Rationale**: `offline` drives the stop sign; the reconnect overlay needs a signal that does not strobe during each probe so its outage clock keeps accumulating (doc comment on `disconnected`).
**Approved**: pending

**Decision**: Hold the manual-check spinner until a snapshot built at or after the click lands, with a 200,000 ms backstop, and do not re-read immediately on a started check.
**Rationale**: The check-start request returns as soon as the detached cycle starts, so an immediate re-read fetches the pre-cycle snapshot. The old 12 s backstop fired on nearly every check while providers were still being polled (doc comment on `CHECK_SAFETY_MS`).
**Approved**: pending

**Decision**: Separate `refresh` (full check) from `reconnect` (re-read).
**Rationale**: An auto-retry loop over a down backend has to stay a light read, never a repeated provider fan-out (comment on `reconnect`).
**Approved**: pending

**Decision**: Publish notifications through a shared frame-subscription set instead of the store's listener set.
**Rationale**: The board state refetches on notifications without opening a second connection ("one connection per tab is the existing contract"). The store's listeners also fire on connection-state changes, which should not trigger a board refetch.
**Approved**: pending

**Decision**: The live poll uses one cache key for every client, so two stores under one query client share a cache entry despite the module header promising isolated stores.
**Rationale**: It stands today because the key carries no client identity. Closing it needs an owner decision on whether the key must include a client identity, and a two-provider test.
**Approved**: pending

**Decision**: Overlapping check requests have no ordering rule; the flags of an earlier call can clear those of a later call, and an overwritten safety timer handle leaves an orphaned timer.
**Rationale**: It stands today because each call manages its own flags and timer assignment independently, with no call identity. Closing it needs the owner to choose an ordering rule (ignore, supersede or queue) and a test that fires two clicks with interleaved responses.
**Approved**: pending

