
- **AppKit / UIKit isolation mechanism**: On this source platform, each of
  the three types is declared `@MainActor` and `public`, with no `Sendable`
  conformance of its own; Swift's actor-isolation rules enforce
  `serialized-access-across-all-three-types` at compile time. `rootNode`
  and `isSyncing` are mirrored from the coordinator's own `$rootNode`/
  `$isSyncing` Combine publishers via `.receive(on: DispatchQueue.main)`.
- **SwiftUI**: All three types are already Combine `ObservableObject`s with
  `@Published` properties — the same reactive primitive SwiftUI's own state
  containers use — so a SwiftUI host can drive any of them directly with
  `@StateObject`/`@ObservedObject` and no adaptation layer; nothing in these
  three files is AppKit-specific despite currently being consumed only by
  AppKit view controllers (see `file-browser-view-controller`,
  `file-tree-outline-view-controller`).
- **Compose**: Model each type as a Kotlin `ViewModel` exposing
  `StateFlow`/`MutableStateFlow` in place of `@Published` — `additional`,
  `expandedPaths`/`selectedPath`, and `rootNode`/`isSyncing` respectively —
  and replace each `onChange` closure with a `SharedFlow<T>` a host collects,
  or a repository interface the `ViewModel` calls directly instead of
  invoking a closure.
- **React/Web**: Port `FileBrowserDirectories`' add/remove/normalize logic as
  a small store (a Zustand/Redux slice or a hand-rolled event emitter) rather
  than a class with mutable fields; back `FileBrowserRestorationState` with
  the same store pattern, writing to `localStorage`/IndexedDB from the same
  "only report when it actually changed" callback this recipe requires;
  `FileTreeManager`'s two debounces map directly onto `setTimeout`/
  `clearTimeout` with the same 500ms/2000ms delays.
- **AppKit / UIKit**: This is the source platform (the `AgenticToolkitMacOS`
  module), but that placement is a module-organization fact, not a technical
  one: none of `FileBrowserDirectories.swift`, `FileBrowserRestorationState.swift`,
  or `FileTreeManager.swift` imports AppKit. Porting these three types to
  iOS/UIKit needs no logic change to them directly; what would need
  replacing lives one layer down, in `DirectoryWatchCoordinator`'s
  `FileSystemWatcher` (FSEvents is macOS-only) and in `IDEDetector`'s static
  `open(project:rootURL:)` helper (which calls `NSWorkspace`, an AppKit-only
  API not used by any of the three types this recipe specifies).
- **WinUI 3**: Model `FileBrowserDirectories` and `FileBrowserRestorationState`
  as `ObservableObject`/`INotifyPropertyChanged` classes (via
  `CommunityToolkit.Mvvm`'s `ObservableObject` base), with `additional` as an
  `ObservableCollection<Uri>` rebuilt through the same
  normalize-then-assign step; there is no direct .NET equivalent of
  `URL.resolvingSymlinksInPath()`, so use `Path.GetFullPath` together with
  `Directory.ResolveLinkTarget` (.NET 6+, `returnFinalTarget: true`) to reach
  the same "compare by resolved location" behavior `add-rejects-existing-root`
  and `root-containing-longest-match` depend on. Persist
  `FileBrowserRestorationState`'s expanded paths and selection through
  `ApplicationData.Current.LocalSettings` or a JSON file under
  `Windows.Storage`, written from the same onChange-only-when-different
  guard. Model `FileTreeManager` as a class composing a `DirectoryWatchCoordinator`
  equivalent built on `System.IO.FileSystemWatcher`, a git-status poller
  invoked from a background `Task`, and the two debounces
  (`fs-change-debounces-git-refresh-500ms`,
  `fs-change-debounces-ide-detection-2000ms`) as two independent
  `DispatcherTimer`s (or `Task.Delay`-based debouncers) restarted on every
  filesystem-watcher callback, mirroring `pendingGitRefresh`/
  `pendingIDEDetection` exactly rather than collapsing them into one timer.

