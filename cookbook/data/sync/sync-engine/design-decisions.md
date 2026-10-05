
### Server manifest is authoritative and complete

**Decision**: Every pull page's manifest is treated as the full enrollment set; a registered resource missing from it is disabled on that page.

**Rationale**: The source comment (fix B1) states the client cannot distinguish "server dropped it" from "server forgot it", so omission is the signal and the server must send the full manifest every page.

**Approved**: pending

### Schema downgrade is a bump

**Decision**: `bumped` uses a not-equal comparison, so a lower manifest `schemaVersion` purges and resyncs exactly like a higher one.

**Rationale**: Per fix A2, mirror rows written under one schema cannot be trusted under another in either direction.

**Approved**: pending

### Unadoptable conflicts quarantine

**Decision**: A conflict with no `current`, or with a `sync_version` that cannot become an integer, is recorded as `.rejected` so the store quarantines it.

**Rationale**: Fixes p2-Minor9 and A3: the old behaviour either dropped the op silently or let `store.apply` throw before `complete`, re-pushing the op every cycle.

**Approved**: pending

### Bounded loops everywhere

**Decision**: Pull no-progress (2), reconcile resets per cycle (3), nested 410 resyncs (1 immediate) and push no-progress all convert a potential hot loop into a regular failure with backoff.

**Rationale**: Each guards a misbehaving or lagging server (the source cites a cohort stall guard and a moving GC horizon); failing into backoff keeps the outbox intact while giving the server time to catch up.

**Approved**: pending

### Joining `syncNow` waits; `kick` does not

**Decision**: A `syncNow` that coalesces into a running cycle suspends until that cycle ends, while `kick` returns at once.

**Rationale**: The doc comment makes `syncNow` an honest "a sync just ran" signal for pull-to-refresh spinners and background-task completion handlers.

**Approved**: pending

### Pause buffers nothing

**Decision**: Kicks during `pause()` are dropped and a pending reason is cleared when a cycle ends paused; `resume()` does not sync.

**Rationale**: `pause()` exists for identity-boundary operations such as a sign-out purge; resurrecting a reason queued before the purge would sync the wrong identity's state.

**Approved**: pending

### Event buffer of 256 newest

**Decision**: `events` buffers the newest 256 events instead of an unbounded buffer.

**Rationale**: The init comment calls it a backstop against a host that never subscribes; both shipped hosts drain continuously, and the obligation to drain still stands.

**Approved**: pending

### Snapshot registrations once per cycle

**Decision**: Registrations are read once per cycle and `prepare` is skipped when the snapshot already covers the effective set (fix H5+H1).

**Rationale**: Avoids a store read and a no-op store write on every steady-state page.

**Approved**: pending

**Decision**: `stop` sets no stopped state, so a cycle in flight when it runs can still arm a retry afterward.
**Rationale**: The engine has no stopped flag for `kick`, `syncNow` or `scheduleRetry` to check, so the late retry fires into a finished event stream. Closing it takes a stopped-state contract that refuses those calls after `stop`, or a documented rule that `stop` must follow `pause`, plus a test for a failure that lands after `stop`.
**Approved**: pending

**Decision**: Version adoption accepts signed and negative `syncVersion` text that is documented as digits only.
**Rationale**: The integer parser used is more permissive than the documented format, so a signed value reaches `apply` and could raise and re-push the op every cycle. Closing it takes a non-negative unsigned check at adoption, or a store contract that accepts signed text, plus a test for "-5" and "+5".
**Approved**: pending

