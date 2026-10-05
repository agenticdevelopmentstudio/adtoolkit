
- **React/Web** (source platform): the two files live under
  `packages/web/packages/status-server/src/libsql/`, on top of
  `drizzle-orm/sqlite-core` and `drizzle-orm/libsql` (including its
  `migrator` submodule), Node's built-in `node:module`
  (`createRequire`) and `node:path`/`node:crypto`, and the
  `@agentic-toolkit/deploy-platform/schema` and `../monitor/deploy-status`
  siblings the schema re-exports from and builds its partial index against
  (the partial index's predicate calls `inFlightSql('')` from
  `../monitor/deploy-status`). The package's own root directory is
  resolved via `createRequire(import.meta.url).resolve('@agentic-toolkit/status-server/package.json')`,
  so `MIGRATIONS_FOLDER` is correct whether the caller runs from `src/`,
  from a built `dist/` chunk, or from a host's vendored `node_modules`
  copy; migrations apply through `drizzle-orm/libsql/migrator`'s
  `migrate`, recording each in a `__drizzle_migrations` bookkeeping table.
  `apiTokens.createdAt` and `deviceAuthorizations.createdAt` are populated
  via a Drizzle `$defaultFn` (`() => new Date()`) rather than a SQL-level
  `DEFAULT`, unlike every other timestamp column in this schema, which
  defaults via Drizzle's `.default(now)` (a SQL `unixepoch()` default).
  The Hono routes and the monitor worker that call `openLibsql`,
  `tuneDbForConcurrency`, and `migrateDb` live outside this recipe's two
  files.
- **SwiftUI / AppKit / UIKit**: an Apple client of this backend is a
  consumer of the HTTP API this schema and its migrations power, not a
  re-implementer of it — it never opens this database directly. If a
  future product needed a companion Swift backend with an equivalent
  embedded store (a Vapor or Hummingbird service, for example), model each
  table as a `Codable` `struct` mirroring its columns 1:1, open the file
  with `GRDB.swift` or `SQLite.swift` rather than Core Data/SwiftData (this
  schema is relational rows with explicit indexes and partial-index
  predicates, not an object graph), issue the same `PRAGMA journal_mode=WAL`,
  `PRAGMA busy_timeout=5000`, and `PRAGMA synchronous=NORMAL` immediately
  after opening, and run migrations inside one transaction, checking for
  each table's existence the way `migrateDb` checks `__drizzle_migrations`.
- **Compose**: same client relationship as SwiftUI/AppKit/UIKit — an
  Android client calls the backend's HTTP API directly; it has no local
  copy of this schema to port. A hypothetical Kotlin backend port would use
  `androidx.sqlite` (or `SQLiteOpenHelper`/`SQLiteDatabase` directly),
  re-issuing the same three pragmas per connection and modeling each table
  as a Kotlin `data class`.
- **WinUI 3**: a WinUI 3 desktop app is likewise an HTTP client of this
  backend, never a direct reader of its database file. If a future product
  needed to reimplement this schema and its concurrency tuning on a .NET
  backend (ASP.NET Core Minimal API over SQLite), port it with
  `Microsoft.Data.Sqlite` rather than `Windows.Storage`'s settings APIs —
  this is relational rows with foreign keys and partial indexes, not
  key-value storage. Open the connection, then issue
  `PRAGMA journal_mode=WAL;`, `PRAGMA busy_timeout=5000;`, and
  `PRAGMA synchronous=NORMAL;` as raw command text exactly as
  `tuneDbForConcurrency` does; run `PRAGMA wal_checkpoint(TRUNCATE);` on the
  same maintenance cadence `checkpointWal` documents. Model `users`,
  `sessions`, and `apiTokens` as EF Core entities (or raw `Microsoft.Data.Sqlite`
  commands, for closer fidelity to this file's own driver-level style) with
  the sha256-hash-only-at-rest columns preserved verbatim, and run each
  migration inside a transaction opened with `BEGIN IMMEDIATE;` the way
  `migrate()`'s own transaction wrapping does, tracking applied migrations
  in a table equivalent to `__drizzle_migrations`.

