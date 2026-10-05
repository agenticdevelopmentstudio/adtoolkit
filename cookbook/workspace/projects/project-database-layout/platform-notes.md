
- **SwiftUI**: this extension itself has no SwiftUI dependency — it
  imports only `Foundation` and calls the C `SQLite3` API through the
  base class's helpers; a SwiftUI caller observes its results the same way
  an AppKit caller does, through whatever wrapper (e.g. an
  `ObservableObject`) the call site builds around `loadTabs`/`saveTabs`.
  The base `ProjectDatabase` is a `public final class` with no `Sendable`
  conformance and no `actor`/`@MainActor` isolation — the mechanism behind
  **caller-must-synchronize-cross-thread-access** — so this extension's
  methods carry no concurrency guarantee of their own. `ProjectDatabaseError`
  is likewise declared `public enum ProjectDatabaseError: Error` with no
  `Sendable` conformance, so the error type itself carries the same
  absence of a compiler-enforced concurrency-safety marker as the store it
  is thrown from.
- **AppKit/UIKit**: same as SwiftUI — no direct AppKit dependency in this
  file; the file's location under `macOS/Features/Projects` reflects
  where the base `ProjectDatabase` and its call sites live today, not a
  hard macOS-only API dependency in this extension's own code.
- **Compose (Android)**: use Room or `android.database.sqlite.SQLiteDatabase`
  in place of the raw `SQLite3` C calls; represent `LayoutNode` as a
  Kotlin `sealed class` (`Leaf`/`Split`) in place of Swift's `indirect
  enum`, `Edge` as a Kotlin `enum class`, and serialize the same
  whole-replace/transaction pattern through Room's `@Transaction`
  methods; because `ProjectDatabase` is not `Sendable` here, the Android
  equivalent should confine writes to a single coroutine dispatcher (e.g.
  `Dispatchers.IO` behind a `Mutex`) rather than assume SQLite's own
  locking is enough.
- **React/Web**: there is no native filesystem or SQLite file; use
  IndexedDB or a WASM SQLite (e.g. wa-sqlite) inside a Worker, and treat
  `workingDirectory`/`project_directories.path` as opaque identifiers
  (e.g. a File System Access API handle key) rather than real filesystem
  paths, since a browser has no equivalent of
  `URL(fileURLWithPath:isDirectory:)`.
- **WinUI 3**: use `Microsoft.Data.Sqlite` with parameterized
  `SqliteCommand`s mirroring the `?`-bound statements here, and a
  `SqliteTransaction` wrapping each whole-replace exactly as
  `saveTabs`/`saveProjectDirectories` wrap theirs in `BEGIN
  IMMEDIATE`/`COMMIT`; represent `LayoutNode` as an `abstract record
  LayoutNode` with `LeafNode`/`SplitNode` subtypes in place of Swift's
  `indirect enum`, and `Edge`/`ComposableTabsAxis` as C# `enum`s; set
  `SqliteConnection`'s command timeout to mirror `sqlite3_busy_timeout`'s
  5000ms rather than relying on the driver's own default.

