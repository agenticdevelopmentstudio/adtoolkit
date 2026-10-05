
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectTree.swift`,
  tested by
  `Tests/AgenticToolkitMacOSTests/Projects/ProjectTreeTests.swift`; it
  imports only `Foundation` and depends on no AppKit, UIKit, or SwiftUI type,
  so it ports unchanged into a SwiftUI-hosted app. A SwiftUI `List` or
  `OutlineGroup` would bind directly to the returned `[ProjectTreeNode]`
  roots and each node's `children`, exactly as `ProjectBrowserViewController`
  binds its `NSOutlineView` today. `ProjectTreeNode` MUST NOT declare
  `Sendable` conformance; because it is a `public final class` holding
  mutable reference state (`children`) with no such conformance, the
  compiler keeps every value of this type confined to the `@MainActor`
  isolation domain it was created in — no caller in the given sources
  passes a `ProjectTreeNode` across isolation domains (contrast
  `GitRepo`'s `Sendable` conformance in `GitRepo.swift`).
- **Compose**: Model `ProjectTreeNode` as a Kotlin class (not a `data class`,
  to preserve `fileprivate`-style construction control via an `internal`
  constructor plus a factory) holding `val name: String`, `val repo:
  GitRepo?`, `val path: String`, and a private `MutableList<ProjectTreeNode>`
  exposed as a read-only `List`; `isFolder` ports as `val isFolder get() =
  repo == null`. Reproduce `@MainActor` confinement by requiring `build` to
  run on `Dispatchers.Main` (Kotlin has no compile-time actor-isolation
  check, so this is a convention the port must enforce by review or a
  runtime assertion, not the compiler). `localizedCaseInsensitiveCompare`
  becomes `String.compareTo(other, ignoreCase = true)` combined with the
  platform's current `Locale` for any locale-sensitive difference.
- **React/Web**: A browser has no filesystem, so `homeDirectory`/`path` have
  no direct analogue unless this pattern runs in a Node-hosted process; there
  represent `ProjectTreeNode` as a plain object `{ name, repo, path,
  children }` and `isFolder` as `repo == null`, using `path.sep`-aware string
  splitting in place of `URL`/`String.split(separator: "/")`. JavaScript's
  single-threaded event loop naturally reproduces the source's `@MainActor`
  confinement without extra work, since nothing here is `async` or spawns a
  worker.
- **AppKit / UIKit**: This is the file's actual runtime home today.
  `ProjectBrowserViewController.viewDidLoad`-driven code calls
  `ProjectTree.build(from: matching)` and stores the result in its
  own `roots` property; its `NSOutlineViewDataSource` methods
  (`outlineView(_:child:ofItem:)`, `outlineView(_:isItemExpandable:)`, etc.) read a `ProjectTreeNode`'s `children` and `isFolder`
  directly to drive the outline view. Nothing in `ProjectTree.swift` itself
  is AppKit-specific, so it ports unchanged to UIKit's `UITableView`/
  `UICollectionView` with a diffable, hierarchy-flattening data source.
- **WinUI 3**: This is the platform this recipe exists to steer. Model
  `ProjectTreeNode` as a plain C# class with `string Name`, `GitRepo? Repo`,
  `string Path`, a `bool IsFolder => Repo is null` computed property, and an
  `IReadOnlyList<ProjectTreeNode> Children` backed by a private
  `List<ProjectTreeNode>` populated only through an internal `Add` method —
  mirroring the source's `fileprivate init`/`add(_:)` restriction with C#
  `internal` visibility rather than a WinUI-specific mechanism. Implement
  `ProjectTree.Build(IReadOnlyList<GitRepo> repos, string? homeDirectory =
  null)` as a static method defaulting `homeDirectory` to
  `Environment.GetFolderPath(Environment.SpecialFolder.UserProfile)`, and
  reproduce `trail`/`standardized` with `string.Split('\\', '/')` plus a
  manual home-prefix comparison (Windows paths use `\`, not `/`, so a
  faithful port must decide the separator convention up front rather than
  hardcoding `"/"`). Bind the returned roots to a
  `Microsoft.UI.Xaml.Controls.TreeView`'s `ItemsSource` (or a `TreeViewNode`
  tree built from it), using `IsFolder` to pick between a folder glyph and a
  project glyph in the `TreeView`'s `ItemTemplate`; because `Build` should
  run on the UI thread the way the source's `@MainActor` requires, guard any
  call from a background context with `DispatcherQueue.TryEnqueue` rather
  than relying on a compiler-enforced actor, since C# has no `@MainActor`
  equivalent.
- **confines-to-ui-thread** (scope): The rule covers a tree node and the tree-building operation; a caller on any other execution context crosses to the UI thread to call the build operation or to read or mutate a node's `children`.

