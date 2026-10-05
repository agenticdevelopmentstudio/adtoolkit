
- **WinUI 3**: No WinUI 3 implementation exists in this repository. A .NET port would implement the same store, transport and trigger-source contracts, hosting the engine as a single-reader task loop, using `Task.Delay` with the same backoff math, a SQLite-backed store for the mirror and outbox, and `NetworkChange` availability events as the connectivity trigger; the wire fixtures are the conformance contract.
- **Core (`AgenticToolkitSync`):** `packages/apple/AgenticToolkit/Sync/*` —
  `SyncEngine.swift`, `SyncEvents.swift`, `SyncWire.swift`, `SyncProtocols.swift`,
  `ADHSyncCatalog.swift`, `JSONValue.swift`, `SyncID.swift`, the `Triggers/*`
  trigger sources. The `Testing/*` fakes (`InMemorySyncStore`, `ScriptedSyncTransport`) are specified separately in `data/sync/sync-testing`.
- **On-disk store (`AgenticToolkitSyncGRDB`):**
  `packages/apple/AgenticToolkit/SyncGRDB/GRDBSyncStore.swift` — the SQLite/GRDB
  `SyncStore` on a `BoundedDatabase` WAL pool.
- **Conformance = the two XCTest bundles:**
  `Tests/AgenticToolkitSyncTests/*` (engine, wire, catalog, events, in-memory
  store) and `Tests/AgenticToolkitSyncGRDBTests/*` (the GRDB store + a
  SyncEngine-over-GRDB integration test).
- **No TypeScript / web implementation exists yet.** The wire types and the
  vendored fixtures (`Tests/AgenticToolkitSyncTests/Fixtures/*.json`) are the
  cross-language contract a future web client would conform to; the fixtures must
  not be edited locally.

