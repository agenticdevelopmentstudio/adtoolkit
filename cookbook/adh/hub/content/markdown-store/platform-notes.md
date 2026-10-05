
- **SwiftUI**: Not a view; a SwiftUI screen observes this store through an
  observable wrapper around it, never by subclassing it or reaching into the
  underlying database directly.
- **Compose**: The Kotlin equivalent would pair a Room- or SQLDelight-backed store
  with the same schema shape, exposed to Compose through a view-model and observable
  state, not observed directly.
- **React/Web**: The web equivalent has no local SQL database; the nearest analog is
  an IndexedDB-backed store with the same pull-only/outbox split, exposed to React
  through a hook, not a component prop.
- **AppKit / UIKit**: this is the source, though neither framework is actually
  linked — the implementation is six plain Foundation files (`MarkdownSchema.swift`,
  `MarkdownProjection.swift`, `MarkdownStore.swift`, `MarkdownTaxonomy.swift`,
  `MarkdownTimestamp.swift`, `MarkdownRemoteWriter.swift`) backed by a local SQLite
  database accessed through GRDB (`BoundedDatabase`), so an AppKit or UIKit
  controller holds a reference and observes it through the same wrapper any other
  consumer uses, never a delegate protocol specific to this component.

  `MarkdownSchema.tables` is the single array `MarkdownProjection.resources`/
  `syncResources` derive from (**table-set**); `markerTable(_:)` generates the
  shared shape for `notes`/`docs`/`papers` (**marker-table-shape**);
  `MarkdownSchema.migrator()` builds the `DatabaseMigrator` and `migrate(_:)` turns
  on foreign-key enforcement before running it (**migration-sequence**); the SQLite
  `PRAGMA table_info` statement is the live-schema introspection the projection's
  hand-maintained column lists are cross-checked against at runtime
  (**schema-drift-guard**).

  `MarkdownTimestamp.string`/`.date` are the one writer/reader pair every
  column-to-date conversion goes through (**single-formatter-pair**,
  **millisecond-write-precision**, **postgres-form-repair**); the pair is backed by
  two `nonisolated(unsafe)` `ISO8601DateFormatter` statics whose thread-safety is
  serialized through one lock, because `ISO8601DateFormatter` itself publishes no
  thread-safety guarantee and `MarkdownStore`'s read path runs on a pool of
  concurrent readers (**formatter-thread-safety**).

  `MarkdownProjection.upsert` implements remote-id remapping, the partial-patch
  delete guard, delete-state normalization, and every column-encoding rule above;
  `isTruthy` implements the truthy-parsing rule; `truncate` implements the
  orphan-purge refusal.

  `MarkdownStore.init` takes the required tenancy ids; `createDocument`,
  `updateDocument`, `publishDocument`/`unpublishDocument`, and `deleteDocument`
  implement the lifecycle methods above; `drainRemoteQueue` implements the queue
  drain, sending each operation through a caller-supplied `MarkdownRemoteWriter`;
  `mutateDocument` is the reentrant merge-then-write update path called out in Edge
  Cases. `drainRemoteQueue`'s own doc comment states the one-drain-at-a-time
  precondition; nothing in `MarkdownStore` enforces it with an actor, lock, or
  semaphore (**drain-mutual-exclusion**).

  `MarkdownTaxonomy` extends `MarkdownStore` with `addCategoryEdge`,
  `removeCategoryEdge`, `createKeyword`, the shared item-assignment path, and
  `deleteCategory`; `categoryNoteCounts`' direct-not-transitive counting rule is
  explicitly modeled on Apple Notes' own folder-badge semantics — a precedent from a
  first-party Apple app, not a general database convention.

  `defaultPath(inHome:token:)` resolves the default database path. Logging goes
  through `MarkdownStore.logger`, a plain `os.Logger` (Apple's unified-logging type)
  rather than a shared logging protocol, because this target does not link the
  framework that protocol lives in; its subsystem is the app's bundle identifier or
  the Swift literal `nil` when none is set, and its category is the literal string
  `"MarkdownStore"`. Error surfaces are typed Swift `enum`s, none conforming to
  `LocalizedError`. `document(from: Row)`, `documents(marker:)`, and `document(id:)`
  are the two read paths that disagree on unreadable-timestamp handling in Edge
  Cases.
- **WinUI 3**: A Windows port would replace the GRDB-backed database with a
  `Microsoft.Data.Sqlite`-backed store, replace the remote-writer contract's `send`
  method with `HttpClient` calls encoding payloads through `System.Text.Json`,
  replace the per-token home directory with a folder under
  `Windows.Storage.ApplicationData`, run the drain as a `Task`, and expose document
  lists to XAML through an `ObservableCollection` with `INotifyPropertyChanged`
  rather than this store's plain array return values.

