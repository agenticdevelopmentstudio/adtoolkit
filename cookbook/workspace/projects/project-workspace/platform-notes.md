
- **SwiftUI**: The source is
  `packages/apple/AgenticToolkit/macOS/Features/Projects/ProjectWorkspace.swift`,
  importing `AppKit`, `AgenticToolkitCore`, `AgenticToolkitCoreUI`,
  `AgenticToolkitCoreMacOS`, and `os`. It calls no AppKit UI API directly —
  it is a plain `@MainActor` model object holding a `GitRepo`, a
  `ProjectDatabase`, a `ComposableTabsLayout`, and two weak object caches. A
  SwiftUI host would still need this exact object feeding a tab-bar view, as
  an `@Observable`/`ObservableObject`-wrapped dependency, not a `View` or
  `Scene` itself. `ProjectWorkspace` is declared `@MainActor` and declares
  no `Sendable` conformance of its own, so every stored property and method
  is confined to the main actor by that declaration alone.
- **Compose**: Model `ProjectWorkspace` as a plain class confined to a single
  coroutine dispatcher (Compose's main-thread dispatcher, mirroring
  `@MainActor`), holding `repo` and `layout` as `MutableState` so dependent
  composables recompose on `update(repo:)`. Reproduce the two `WeakCache`s
  with a `WeakHashMap`/`java.lang.ref.WeakReference`-backed map keyed by the
  resolved directory path, evicted the same way — lazily, on next lookup,
  rather than by an explicit listener. Route every persisted read/write
  (`storedTabs`, `paneState`, `setting`, `projectDirectories`) through a
  coroutine-based `ProjectDatabase` port that mirrors this file's
  swallow-and-log convention on every path except the one this recipe flags
  as a pending decision.
- **React/Web**: There is no local filesystem worktree or SQLite file to
  scope this object to on the web; a browser-hosted project workspace would
  keep `repo`/tabs/pane-state/settings as component state populated from and
  persisted through a server-side API standing in for `ProjectDatabase` (see
  `adtoolkit://cookbook/workspace/projects/project-database`), and would
  reproduce the two weak, directory-keyed caches with a JavaScript `WeakMap`
  (optionally paired with `FinalizationRegistry` to detect eviction) keyed by
  a normalized directory identifier, since JavaScript has no
  `resolvingSymlinksInPath()` equivalent of its own.
- **AppKit / UIKit**: The source already is this tier — a plain
  `@MainActor`-confined `NSObject`-free model class with no `NSViewController`
  of its own. A UIKit (iOS) port carries the tab-tree, pane-state, settings,
  and directory-cache logic unchanged; it would still need its own
  `FileBrowserDirectories`/`GitStatusProvider`-equivalent collaborators, and,
  per the multi-checkout note in
  `adtoolkit://cookbook/workspace/projects/project-controller`, iOS
  sandboxing makes exposing more than one linked worktree under one project
  an unusual arrangement to design a browser for.
- **WinUI 3**: Port `ProjectWorkspace` as a plain C# class with no interface
  requiring thread-affinity of its own, touched only from the UI thread
  (`DispatcherQueue`) by convention — the same discipline
  `adtoolkit://cookbook/workspace/projects/branch-controller`'s WinUI
  port assumes for `@MainActor`. Reproduce the two `WeakCache`s with a
  `Dictionary<string, WeakReference<T>>` (or `ConditionalWeakTable`) keyed by
  a normalized, reparse-point-resolved path (`Path.GetFullPath`/
  `FileInfo.FullName`, mirroring `resolvingSymlinksInPath()`), pruning dead
  entries the same way — lazily, on the next lookup for any key, not on a
  timer. Reproduce **directory-addition-fans-out-to-every-live-sibling** by
  iterating every live entry in that table and calling an equivalent
  `ReplaceAdditional` on each, and reproduce
  **pane-state-list-json-encoded** with `System.Text.Json` in place of
  `JSONEncoder`/`JSONDecoder`. Route every persisted accessor
  (`storedTabs`/`saveTabs`, `paneState`/`setPaneState`, `setting`/
  `setSetting`, `loadProjectDirectories`/`saveProjectDirectories`) through
  the same SQLite-backed port `adtoolkit://cookbook/workspace/projects/project-database`
  and `adtoolkit://cookbook/workspace/projects/project-database-layout`
  describe, keeping this file's swallow-and-log convention on every path
  except the one flagged as a pending decision above.
- **confines-to-ui-thread** (scope): The workspace has no thread-safety guarantee of its own; every stored property and method is confined to the UI thread by that declaration alone.

