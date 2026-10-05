
### Coalesce into a pending op, never an inflight one

**Decision**: A second local edit to a row with a `pending` op updates that op in place, keeping its `op_id` and original `base_version`; an `inflight` op is never modified.

**Rationale**: The `stage` doc comment (sync fix-wave item p2a) records that two ops with the same base version make the server apply the first and stale-conflict the second, silently dropping the newer edit. An inflight op may already be at the server, and its replay under the same `op_id` must carry the same content.

**Approved**: pending

### Strict parsing on pull, lenient on completion

**Decision**: An unparseable `syncVersion` in `apply` throws `invalidChange`, but an unparseable `newVersion` in `complete` is skipped silently while the outbox row is still deleted.

**Rationale**: The source comments explain that coercing to 0 would corrupt version ordering, so `apply` fails loudly; but throwing inside `complete` would roll back the outbox deletion and wedge the op on replay even though the server already applied it.

**Approved**: pending

### Inflight ops are replayed until completed

**Decision**: `pendingOps` returns `inflight` ops again on every call.

**Rationale**: The `pendingOps` doc comment states that replaying the same opIds after a crash or an unfinished round-trip is covered by the server contract's idempotency guarantee, so re-sending is safe and nothing is stranded.

**Approved**: pending

### Identity change clears the outbox; resync does not

**Decision**: `resetForResync` keeps every outbox op; `purgeForIdentityChange` deletes all of them, including quarantined ones, and asks the projection to drop its local-only state.

**Rationale**: The `purgeForIdentityChange` doc comment explains that a resync keeps the same identity, which still owes the server its queued edits, while pushing a departing identity's ops under new credentials would misattribute them; `MarkdownProjection`'s sidecar outbox is the cited case for `purgeIdentityState`.

**Approved**: pending

### Registrations and the conflict audit survive every purge

**Decision**: No purge path deletes `_sync_conflicts`, and only `purgeResources` deletes registrations.

**Rationale**: The doc comments call registrations app-level rather than per-identity state (so the next identity need not re-`prepare`), and call the conflict audit a historical record never read back into a sync decision.

**Approved**: pending

### Offset pagination on the mirror

**Decision**: `liveRows` pages with `LIMIT`/`OFFSET` ordered by `id`.

**Rationale**: The `liveRows` doc comment says the mirror shadows the backend's own offset/limit REST contract because the daemon is a transparent proxy; the `O(offset)` cost is bounded by callers capping `limit` (`MirrorServer`'s `listLimit`, 200).

**Approved**: pending

### Projections see a whole purge batch at once

**Decision**: Every truncation hands all claimed resources to `truncate(resources:in:)` in one call.

**Rationale**: The `deleteMirrorRows` comment explains that a projection with foreign keys between its own tables can only tell a legal whole-family purge from an orphaning partial one by seeing the whole batch.

**Approved**: pending

### SyncMirrorProjection

**Decision**: Typed storage is opt-in per resource through a projection, and the `isFullRow:` and `purgeIdentityState` requirements have defaults.

**Rationale**: The protocol doc says the JSON mirror survives schema evolution without migrations and is the right default, while indexed or foreign-keyed local storage needs real columns; the defaults keep projections written before those requirements existed source-compatible.

**Approved**: pending

**Decision**: The JSON mirror replaces a row's data wholesale with a staged patch rather than merging it, so a partial patch hides the fields it omits from the local view until the next pull.
**Rationale**: The mirror, the outbox (which merges patches) and the projection path (which treats a staged mutation as a deliberate partial patch) disagree about what a patch means. Closing it needs the sync owner to decide whether the mirror should merge instead, a change to the mirror write, and a test asserting the intended local view.
**Approved**: pending

