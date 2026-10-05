
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectDatabase.swift`,
  importing only `Foundation`, `SQLite3` (the C SQLite library linked
  directly, not `Core Data` or `SwiftData`), `AgenticToolkitCore`, and
  `AgenticToolkitDatabase` (for `AppStorageLocation`); it depends on no UI
  framework, and a caller anywhere in a SwiftUI app — an `@Observable` view
  model, an `App`'s startup code — constructs and owns one instance
  directly. `ProjectDatabase` is declared as a plain `final class` with no
  `Sendable` conformance, no `actor` keyword, and no `@MainActor`
  annotation — the mechanism behind
  **caller-must-synchronize-cross-thread-access** — so the compiler keeps
  it in the isolation domain of whichever context created it and does not
  itself enforce any cross-thread safety. Its one connection is stored as
  `database: OpaquePointer?`, opened in `init(path:)` and closed in
  `deinit` only when non-`nil` — the mechanism behind
  **connection-closed-on-teardown**. `columnExists`, `schemaVersion`,
  `queryRepos`, `execute`, `executeBound`, `forEachRow`, `stepRow`,
  `bindText`, `bindOptionalText`, `bindOptionalDate`, `columnText`,
  `columnDate`, `queryScalarString`, and the `database` property itself
  are all declared without the `public` modifier, restricting them to
  callers in the same module; `queryScalarString` is called by no method
  in this file, existing solely for `ProjectDatabase+Layout.swift`, a
  sibling extension in the same module, to call.
- **Compose**: Port the SQLite access with `androidx.sqlite` or a light
  wrapper over `android.database.sqlite.SQLiteOpenHelper`/`SQLiteDatabase`,
  keeping the same one-connection-per-store shape; run the four migrations
  inside `SQLiteDatabase.beginTransactionNonExclusive()`/`endTransaction()`,
  re-issue the `foreign_keys=ON` pragma per connection the same way opening
  the connection does here, and represent `GitRepo` as the Kotlin `data
  class` the sibling `GitRepo` recipe already specifies.
- **React/Web**: A browser has no filesystem or SQLite; if this pattern is
  ported into a Node-hosted process (e.g. an Electron main process or a
  local dev server), use `better-sqlite3` or `node:sqlite`, apply the same
  `PRAGMA journal_mode=WAL`, `PRAGMA foreign_keys=ON`, and a busy-timeout
  equivalent (`better-sqlite3`'s `pragma('busy_timeout = 5000')`), and run
  the migration chain inside one transaction — checking `PRAGMA table_info`
  for column existence the same way this file's column-existence check
  does before any `ALTER TABLE`.
- **AppKit / UIKit**: Identical to the SwiftUI note — nothing in this file
  is tied to a UI framework; it ports unchanged to either, or to a headless
  command-line tool, since this component's own design rationale for the
  default path explicitly notes "this is the same registry the command
  line tools read".
- **WinUI 3**: Port with `Microsoft.Data.Sqlite` (or the raw `sqlite3`
  P/Invoke layer for closer fidelity) rather than `Windows.Storage`'s
  roaming or local settings APIs, since this component's contract is
  relational rows with foreign-key cascades, not key-value settings
  storage. Open the connection, then issue `PRAGMA journal_mode=WAL;` and
  `PRAGMA foreign_keys=ON;` immediately after, exactly as opening the
  connection does here, and issue `PRAGMA busy_timeout=5000;` to match the
  5-second wait (`Microsoft.Data.Sqlite` has no dedicated
  `SQLITE_OPEN_FULLMUTEX` flag, but serializes access per connection by
  default, preserving the same one-connection, thread-safe-by-default
  shape). Run the four migrations inside a transaction opened with `BEGIN
  IMMEDIATE;`/`COMMIT;`/`ROLLBACK;` issued as raw command text the way this
  file's own execute operation does, guarding each `ALTER TABLE` with a
  `PRAGMA table_info('table')` read the way this file's column-existence
  check does. Model `GitRepo` as the C# `record` the sibling `GitRepo`
  recipe specifies, and keep this component's own operations
  synchronous — this file performs every SQL call synchronously on the
  caller's thread — letting a `Task.Run` at the call site, not inside this
  component, move a call off a UI dispatcher thread.
- **caller-must-synchronize-cross-thread-access**: On Apple platforms the class carries no actor isolation and no `Sendable` conformance.

