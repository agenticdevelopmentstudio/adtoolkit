
- **SwiftUI**: None of these four files imports SwiftUI, but
  `DirectoryWatchCoordinator` and `FileTreeNode`'s `ObservableObject` +
  `@Published` conformances are consumable directly by a SwiftUI view via
  `@StateObject`/`@ObservedObject` with no adapter layer. A SwiftUI port
  would keep this model layer unchanged and bind a `List` or `OutlineGroup`
  to `rootNode`'s `children`, calling `loadChildrenIfNeeded()` from
  `.onAppear` or the row's disclosure action, in place of the AppKit
  `NSOutlineView` consumer described in
  [File Tree View](adtoolkit://cookbook/workspace/files/file-tree-view).
- **Compose**: Model `@Published var children`/`isSyncing` as
  `mutableStateOf`/`StateFlow` fields observed from a `ViewModel`; run
  `fullSync()`/`handleChanges`'s background reads on
  `kotlinx.coroutines.Dispatchers.IO` inside a coroutine scope in place of
  `DispatchQueue.global`; Android has no FSEvents equivalent, so the watcher
  needs either `java.nio.file.WatchService` (JVM-side polling) or a
  platform `FileObserver`, coalesced on a timer to approximate the `0.5`
  second latency; render the tree as a `LazyColumn` with per-row expand
  state driving a lazy child-load call.
- **React/Web**: A browser sandbox has no direct file-system access at all;
  in a Node-hosted (Electron-style) app, use `fs.promises.readdir` as the
  `contentsOfDirectory` analog and `chokidar` or `fs.watch` (debounced to
  match the `0.5` second latency) as the `FSEventStreamCreate` analog; hold
  `children`/`isSyncing` in React state (`useState`/`useReducer`) or a store
  (Zustand/Redux), and render the tree with a virtualized list component
  that calls the lazy-load function on row expansion.
- **AppKit / UIKit**: The source
  (`packages/apple/AgenticToolkit/macOS/UI/ViewControllers/FileBrowser/Model/FileSystem/`,
  tested by `Tests/AgenticToolkitMacOSTests/FileBrowser/DirectoryWatchCoordinatorTests.swift`
  and `FileTreeNodeTests.swift`) is macOS-only — it imports `CoreServices`
  for `FSEvents`, which has no iOS counterpart, and lives under a
  `macOS`-specific source directory with no `#if os(iOS)` branch. The direct
  AppKit consumer is `FileTreeOutlineViewController`
  (see [File Tree View](adtoolkit://cookbook/workspace/files/file-tree-view)).
  An iOS port needs a different watch mechanism entirely — a
  `DispatchSource` file-descriptor watch or a polling timer — since
  `FSEventStreamCreate` is unavailable there.
  Swift/AppKit mechanism detail folded in from the normative text above:
  `FileTreeConfig` is declared a `Sendable struct` with three `let` stored
  properties, so its immutability is compiler-enforced rather than merely
  documented. `loadChildrenIfNeeded()` is declared `@MainActor`, its
  background read runs on `DispatchQueue.global(qos: .userInitiated)`, and
  its result is published back via `DispatchQueue.main.async` with a
  `self?.children = ...` guard that no-ops if the node has already been
  deallocated; `DirectoryWatchCoordinator` itself is declared `@MainActor`,
  with `rootURL`/`excludedPrefixes`/`config` as `let` properties fixed at
  `init`. `FileSystemWatcher` is declared
  `final class FileSystemWatcher: @unchecked Sendable`, so the compiler does
  not independently verify its internal thread safety — callers are trusted
  to serialize their own access to `start()`/`stop()`. The ignore-pattern
  check (`shouldIgnore(_:patterns:)`) is implemented with POSIX `fnmatch`
  called with flags `0`. Icon identifiers are SF Symbol names:
  `"shippingbox.fill"` (package), `"brain"` (`.claude`),
  `"arrow.triangle.branch"` (`.git`), `"folder.fill.badge.gearshape"`
  (`Sources`/`Source`/`src`), `"folder.fill.badge.questionmark"`
  (`Tests`/`test`/`tests`), `"folder.badge.gearshape"` (other dotfile
  directories), `"folder.fill"` (generic directory), `"doc"` (generic
  document fallback), sourced from `CustomFileTypeMappings.mapping(for:)`
  and `FileTypeIcons.builtInIcon(for:)`. The watcher creates its FSEvents
  stream with `kFSEventStreamEventIdSinceNow`, a latency of `0.5` seconds,
  and flags `kFSEventStreamCreateFlagFileEvents |
  kFSEventStreamCreateFlagUseCFTypes`; its callback dispatches to the
  handler via `DispatchQueue.main.async` and force-casts `eventPaths` via
  `unsafeBitCast(eventPaths, to: NSArray.self) as! [String]` (with an inline
  `swiftlint:disable:this force_cast` comment — see Design Decisions), a
  cast whose safety depends entirely on `kFSEventStreamCreateFlagUseCFTypes`
  having been passed to `FSEventStreamCreate`. `handleChanges(_:)` computes
  affected directories via `(path as NSString).deletingLastPathComponent`.
  Logging goes through the `Loggable` protocol, whose `category` is derived
  from the conforming type's own name and whose subsystem is
  `Bundle.main.bundleIdentifier`; `FileSystemWatcher.start()` logs its root
  path with an explicit `privacy: .public` annotation
  (`logger.info("Started file system watcher for \(self.rootPath, privacy: .public)")`),
  overriding `os.log`'s default private-by-default redaction for
  string-interpolated values.
- **WinUI 3**: `System.IO.FileSystemWatcher` is the direct analog to
  `FSEventStreamCreate`/`FSEventStreamSetDispatchQueue`, but its
  `Changed`/`Created`/`Deleted`/`Renamed` events fire per-change rather than
  FSEvents' coalesced batches, so a port needs its own `System.Threading.Timer`
  or `Task.Delay` coalescing buffer to reproduce the `0.5` second latency of
  `watcher-stream-configuration`. Use `ObservableCollection<TreeNode>`
  plus `INotifyPropertyChanged` (or a `CommunityToolkit.Mvvm`
  `ObservableObject`/`[ObservableProperty]`) as the `@Published`/
  `ObservableObject` analog for `rootNode`/`children`.
  `Directory.EnumerateFileSystemEntries` or
  `DirectoryInfo.EnumerateFileSystemInfos` is the `contentsOfDirectory`
  analog; run it on `Task.Run` (the `DispatchQueue.global` analog) and marshal
  results back through the captured `SynchronizationContext` or
  `DispatcherQueue.TryEnqueue` (the `DispatchQueue.main.async` analog). .NET
  has no built-in `fnmatch`; reproduce `node-should-ignore-glob-match` with
  `Microsoft.Extensions.FileSystemGlobbing` or a hand-rolled wildcard
  matcher. For the lazy-load-on-expand behavior
  (`node-load-children-if-needed-guard`), use a `TreeView`/
  `TreeViewNode.HasUnrealizedChildren` plus the `Expanding` event — the same
  mapping this component's own consumer recipe's WinUI 3 bullet already
  uses for `expand-loads-children-lazily`.

