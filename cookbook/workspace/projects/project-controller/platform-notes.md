
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectController.swift`,
  built on `AppKit` (indirectly, through `ComposableTabsTabItemDataSource`'s
  `NSViewController`-hosting `TabItem`) and `AgenticToolkitCore`
  (`ProjectWorkspace`, `ProjectCheckout`, `ProjectTabReconciler`, `GitClient`,
  `CommandRegistry`, `Edge`, `TabRecord`, `Loggable`). It uses no SwiftUI API
  of its own; a SwiftUI-hosted window would still need this controller as a
  plain `@MainActor` observable object feeding a tab-bar view, not a
  `View`/`Scene` itself. Conformance to `ComposableTabsTabItemDataSource` is
  how **tab-item-data-source-conformance** is implemented: this type
  answers `composableTabsWindowController(_:tabItemFor:on:)` directly
  rather than delegating it, and that protocol's `TabItem` return type is
  what makes **tab-item-resolves-directory-then-branch-controller**'s
  `.title`/`.viewController` cases concrete. `ProjectController` is
  declared `@MainActor` and holds no `Sendable` conformance of its own —
  every property and method is confined to the main actor by that
  declaration alone. A `SWIFT_STRICT_CONCURRENCY: complete` build enforces
  this at compile time: attempting to call `open()` or read `checkouts`
  from a `nonisolated` context with no `await` and no `@MainActor` hop
  fails to compile, so there is no runtime path that reaches this type off
  the main actor — the guarantee is verified at build time, not by a
  runtime test.
- **Compose**: Model `ProjectController` as a plain `@MainActor`-confined
  class (or a class dispatched onto Compose's main-thread dispatcher) holding
  `checkouts: List<ProjectCheckout>` and a `Map<ProjectCheckout,
  BranchController>`, both as `MutableState`/`StateFlow` so a tab-bar
  composable recomposes on change. Replace the chained-`Task` serialization
  (**reconcile-calls-chain-in-order**) with a single-threaded Kotlin
  `Channel`/`Mutex`-guarded coroutine sequence that awaits the previous
  reconcile's `Deferred` before starting the next, preserving call order over
  completion order. Represent `onTabsDidChange`/`onWillChangeTabs`/
  `onTabItemsNeedRefresh` as `SharedFlow<Unit>` emissions or plain lambda
  properties.
- **React/Web**: There is no filesystem worktree on the web, so this
  component has no direct web port; a browser-hosted project switcher backed
  by a server-side git service would model `checkouts`/`branchControllers` as
  component state populated from an API call standing in for
  `gitClient.worktrees(in:)`, serialize the chained-reconcile ordering
  guarantee as a request queue keyed by project id (so an overlapping
  "refresh" request can never let a stale response overwrite a fresher one),
  and represent the three callbacks as ordinary event-emitter events.
- **AppKit / UIKit**: The source already is effectively AppKit (through the
  `ComposableTabsTabItemDataSource`/`TabItem` contract it implements); a
  UIKit (iOS) port would replace `NSViewController`-hosted `TabItem`s with
  `UIViewController`-hosted ones and would need its own worktree-listing
  affordance in place of `git worktree list`, since iOS sandboxing makes
  multiple linked worktrees of one repository an unusual arrangement to
  expose in a mobile UI; the checkout/branch-controller reconciliation logic
  ports unchanged.
- **WinUI 3**: Port `ProjectController` as a plain C# class holding
  `ObservableCollection<ProjectCheckout> Checkouts` and a
  `Dictionary<ProjectCheckout, BranchController> BranchControllers`, with no
  interface requiring thread-affinity of its own — mirror `@MainActor`
  confinement by only ever touching this object from the UI thread
  (`DispatcherQueue`), the same discipline `BranchController`'s WinUI port
  already assumes (see `adtoolkit://cookbook/workspace/projects/branch-controller`).
  Reproduce **reconcile-calls-chain-in-order** with a stored `Task`
  (previous reconcile) that the next call `await`s before starting its own
  work — the same continuation-chaining pattern, not a `SemaphoreSlim`, so
  ordering is decided by *when a call arrived* rather than by whichever task
  wins a lock. Represent `onTabsDidChange`, `onWillChangeTabs`, and
  `onTabItemsNeedRefresh` as C# `event Action?` members (or plain
  `Action?` properties, matching the source's own optional-closure shape
  rather than .NET's multicast-delegate convention). Read worktrees with
  `System.Diagnostics.Process` running `git worktree list --porcelain`
  through the same single-door `GitClient` WinUI port
  `adtoolkit://cookbook/workspace/projects/branch-controller` describes,
  and reproduce the main-first-then-git-order partition
  (**checkouts-ordered-main-first-then-git-order**) with `Where`/`Concat`
  rather than `OrderBy`, since LINQ's `OrderBy` is stable but a hand-rolled
  comparator equivalent to a two-way `sorted(by:)` would not be.

