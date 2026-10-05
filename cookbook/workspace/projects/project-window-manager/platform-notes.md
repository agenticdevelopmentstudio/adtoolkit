
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectWindowManager.swift`,
  built on `AppKit` (`NSApp`, `NSWindow`, `NSNotification`), `Combine`
  (`ObservableObject`/`@Published`), `os` (its `Logger`, via `Loggable`), and
  `AgenticToolkitCore` (`GitRepo`, `GitClient`, `ProjectWorkspace`,
  `ProjectController`, `ProjectsCoordinator`, `ProjectOpening`,
  `CommandRegistry`, `ComposableTabsWindowController`, `ProjectLanguageServices`,
  `PendingTeardowns`). It uses no SwiftUI API; a SwiftUI-hosted project
  browser would still need this type as a plain `@MainActor` `ObservableObject`
  feeding a `WindowGroup`/`NSHostingController`, not a `Scene` itself.
  `ProjectWindowManager` is declared `@MainActor` and declares no `Sendable`
  conformance of its own, so every stored property and method is confined to
  the main actor by that declaration alone.
- **Compose**: Model `ProjectWindowManager` as a plain `@MainActor`-confined
  class (or dispatched onto Compose's main-thread dispatcher) holding a
  `Map<UUID, WindowController>`, a `List<UUID>` for open order, and a
  `StateFlow<List<UUID>>` in place of `@Published var openWorkspaceIDs`.
  Replace the `NSWindow.willCloseNotification`/`didBecomeKeyNotification`
  observers with the host platform's own window lifecycle callbacks, keeping
  the same ordering rule — deregister first, then run the teardown a
  coroutine scope can outlive its window's own scope (mirroring
  **close-teardown-added-to-shared-registry**'s detached-teardown registry).
- **React/Web**: There is no per-project native window on the web; the
  closest analogue is a browser tab or a workspace panel keyed by project id
  in client state, with `restorePlan`'s pure reopen/forget split reproduced as
  a plain function over persisted "was this project open" flags read from
  `localStorage` or a user-settings endpoint, and the language-server
  teardown concern replaced by whatever cancels in-flight requests for a
  closed panel's editor sessions.
- **AppKit / UIKit**: The source already is AppKit; a UIKit (iOS) port would
  replace `NSWindow`/`NSWindowController` lifecycle notifications with
  `UIWindowScene`/`UIScene` lifecycle delegate callbacks, and would need its
  own multi-window story since iOS treats "one window per project" as a
  multi-scene arrangement rather than AppKit's independent `NSWindow`s; the
  controller-pairing, restore-plan, and teardown-draining logic ports
  unchanged.
- **WinUI 3**: Port `ProjectWindowManager` as a plain C# class holding
  `Dictionary<Guid, Window>` (`controllers`), `List<Guid>` (`openOrder`), and
  an `ObservableCollection<Guid>` or `event Action?`-backed property in place
  of `openWorkspaceIDs`/`onOpenProjectsChanged`, with no interface requiring
  thread-affinity of its own — mirror `@MainActor` confinement by only ever
  touching this object from the UI thread (`DispatcherQueue`), the same
  discipline `ProjectController`'s WinUI port already assumes (see
  `adtoolkit://cookbook/workspace/projects/project-controller`). Reproduce
  `NSWindow.willCloseNotification`'s `queue: nil` synchronous delivery
  (**close-observer-uses-nil-queue**) with `Window.Closed`, handled inline on
  the UI thread rather than through a dispatcher post, so a scan that closes a
  window and deletes its row in the same call stack still runs its cleanup
  before that row is gone. Reproduce **close-teardown-added-to-shared-registry**
  with a small `PendingTeardowns`-equivalent — a `Dictionary<int, Task>` that a
  window-close `Task.Run`-free async method adds itself to and that quit's
  own async shutdown drains in a loop — rather than firing a bare
  `Task.Run(async () => ...)` that a process exit can orphan. Read and write
  the persisted "window open" flag through the same `System.Data.Sqlite`-backed
  settings store `adtoolkit://cookbook/workspace/projects/project-database`
  describes, using `HttpClient`/`System.Text.Json`/`Task`/`async` and
  `Windows.Storage` only where a networked or file-based collaborator this
  manager delegates to (git, language servers) needs them — this type itself
  makes no HTTP call and reads no `Windows.Storage` file directly.
- **confines-to-ui-thread** (scope): The manager has no thread-safety guarantee of its own; every stored property and method is reached only from the UI thread.

