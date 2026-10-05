
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/BranchController.swift`,
  built on `AppKit` (`NSHashTable`, `NSMenu`, `NSMenuItem`, `NSWorkspace`,
  `NSPasteboard`) and `AgenticToolkitCore` (`ProjectCheckout`, `GitClient`,
  `GitStatusProvider`, `AppCommand`, `TabPaneDataSource`/`TabPaneDelegate`,
  `Edge`, `TabPaneStatusSymbol`, `ClosureMenuItemTarget`). It uses no
  SwiftUI API; a SwiftUI-hosted pane would still need an `NSViewController`
  bridge (or its own `TabPaneDataSource`-equivalent) to reach this
  component's data. It is declared `@MainActor` and holds no `Sendable`
  conformance of its own, so every stored property and method is confined
  to the main actor by that declaration alone, not by any lock the type
  defines itself. Because `NSMenuItem.target` is a weak reference, each
  context menu item's `ClosureMenuItemTarget` is also assigned to the
  item's `representedObject` so it stays retained for the item's lifetime;
  enablement is likewise routed through
  `ClosureMenuItemTarget.validateMenuItem(_:)`, the path
  `NSMenu.autoenablesItems` consults, rather than set once on
  `NSMenuItem.isEnabled`.
- **Compose**: Model this component as a plain class (or, given its
  main-thread confinement, a class annotated for Compose's main-thread
  dispatcher) holding `checkout`, `gitClient`, `statusProvider`, and a
  mutable `currentBranch` `State`/`MutableState`. Replace the weak
  `NSHashTable` of panes with a `MutableList` of weakly-held pane view
  models (Kotlin has no built-in weak collection; a `WeakHashMap`-backed
  wrapper is the closer match) keyed by `(edge, tabID)`. Represent the
  three commands as a `List` of a small `AppCommand`-equivalent data class,
  and build a context menu (`DropdownMenu`) from that list the same way.
- **React/Web**: There is no filesystem worktree or native context menu on
  the web, so this component has no direct web port; a browser-hosted
  equivalent (a project-switcher panel backed by a server-side git service)
  would model `checkout`/`currentBranch` as component state, `commands` as
  an array of `{ id, title, category, run }` objects rendered into a
  context-menu component, and `refresh()` as an async function that awaits
  a server call rather than a local subprocess.
- **AppKit / UIKit**: The source already is AppKit; a UIKit (iOS) port has
  no direct equivalent for `NSMenu`-based context menus (`UIMenu` is the
  closer analogue) or for `NSWorkspace.activateFileViewerSelecting` (no
  Finder-equivalent exists on iOS) or `NSPasteboard` (`UIPasteboard`
  instead); the branch-tracking and pane-identity behavior ports unchanged.
- **WinUI 3**: Port this component as a plain C# class holding
  `ProjectCheckout Checkout`, the injected git client and status provider,
  and a `string? CurrentBranch` property, with no interface requiring
  thread-affinity of its own — mirror the main-thread confinement by only
  ever touching this object from the UI thread (`DispatcherQueue`), the
  same discipline the git status provider's WinUI port already assumes
  (see `adtoolkit://cookbook/workspace/files/git-status-provider`).
  Replace `NSHashTable<TabPaneViewController>.weakObjects()` with a
  `List<WeakReference<TabPaneViewController>>` (or a
  `ConditionalWeakTable`), pruning dead entries on each scan since .NET has
  no automatic weak-collection eviction. Represent the three commands as
  `ICommand` (or a small `AppCommand`-equivalent record with `Id`, `Title`,
  `Category`, `Func<Task> Run`) and build the pane's context menu from a
  `MenuFlyout` populated the same way `tabPane(_:contextMenuFor:)` populates
  an `NSMenu` — no `ClosureMenuItemTarget`/weak-`target` retention concern
  exists in WinUI, since a `MenuFlyoutItem.Command` is strongly held by the
  flyout. Use `Windows.ApplicationModel.DataTransfer.Clipboard.SetContent`
  for Copy Path and `Windows.Storage.Pickers` or `Process.Start("explorer.exe",
  "/select,\"" + path + "\"")` for the Reveal-in-Finder equivalent. Read the
  current branch with `HttpClient`-free process invocation
  (`System.Diagnostics.Process` running `git`) via the same single-door
  client `GitClient`'s WinUI port already centralizes, and mirror the
  detached-HEAD-vs-error distinction exactly: a successful call that
  resolves to no branch name MUST clear `CurrentBranch`, while a thrown
  exception MUST leave it untouched.

