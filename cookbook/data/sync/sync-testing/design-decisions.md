
### Fakes ship in the framework

**Decision**: The fakes live in the production `AgenticToolkitSync` target under `Sync/Testing/`, not in a test target.

**Rationale**: The source comment names this the toolkit convention (see `Core/Chat/MockChatSession.swift`), so host apps' tests and previews can use the same fakes as the toolkit's own tests.

**Approved**: pending

### Parity with GRDBSyncStore

**Decision**: `InMemorySyncStore` reproduces `GRDBSyncStore`'s atomic apply, `syncVersion` validation, coalescing, inflight replay, unparseable-`newVersion` skipping and unregistered-purge no-op.

**Rationale**: The doc comments say the fakes must not "lie" about the real store (sync fix-wave items p2a, p2o, A5, E3/F5), so engine tests run against the fake predict behavior on SQLite.

**Approved**: pending

### One entry for registration and rows

**Decision**: Schema version and rows are held in one `ResourceState` value per resource.

**Rationale**: The source comment says key presence IS the registration truth, replacing two dictionaries that had to be kept in step by hand.

**Approved**: pending

### Inflight ops are replayed, never coalesced

**Decision**: `pendingOps` marks ops inflight and returns them again; `stage` never edits an inflight op.

**Rationale**: A push that never completed must be retried under the same opId, because the server ledgers results per opId; editing an op already sent would change what that opId means.

**Approved**: pending

### Default transport responses

**Decision**: An empty script yields an empty pull echoing the cursor (or "empty") and an all-applied push.

**Rationale**: Tests script only the calls they care about; every other cycle step succeeds quietly.

**Approved**: pending

