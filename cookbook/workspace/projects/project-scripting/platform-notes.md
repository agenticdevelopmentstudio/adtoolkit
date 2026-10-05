
- **SwiftUI**: The source is `packages/apple/AgenticToolkit/macOS/Features/Projects/Scripting/ProjectWindowManager+Scripting.swift`,
  plus the three wrapper types under `macOS/UI/ViewControllers/ComposableTabs/Scripting/`,
  all built on `AppKit` (`NSObject`, `NSScriptObjectSpecifier`) and
  `AgenticToolkitCore`/`AgenticToolkitMacOS` (`ProjectWindowManager`,
  `ComposableTabsWindowController`, `ProjectController`, `BranchController`).
  `ProjectWindowManager` is declared `@MainActor` with no `Sendable`
  conformance, and each of the three wrapper classes independently repeats
  the `@MainActor` declaration on itself, enforcing main-thread
  confinement at compile time. None of the four files uses SwiftUI; a
  SwiftUI-hosted project window would still need this same
  `NSObject`-based Cocoa Scripting bridge, since
  `NSScriptCommand`/`NSScriptObjectSpecifier` are AppKit/Foundation types
  with no SwiftUI equivalent.
- **Compose**: There is no Cocoa Scripting (AppleScript) equivalent on
  Android, so a Compose port would drop the `NSObject`/`@objc`/`objectSpecifier`
  machinery entirely and keep only the enumeration and git-branch-resolution
  logic: a plain function or repository method that maps open project
  windows to a `List` of view models, each carrying the same fields
  (`uniqueID`, `name`, tab list, branch), with the weak/strong holding
  distinctions replaced by whatever lifecycle scoping (`ViewModel`,
  `remember`) Compose already uses to avoid keeping a closed screen's data
  alive.
- **React/Web**: There is no OS-level scripting bridge on the web either; a
  browser port would expose the same three enumerations and lookups as a
  small internal API (or a debugging/automation endpoint) returning plain
  JSON objects with the same field names, and would resolve a tab's branch
  by asking a server-side git service rather than a local `BranchController`.
- **AppKit / UIKit**: The source already is AppKit. iOS has no
  `NSScriptCommand`/Cocoa Scripting equivalent at all (no AppleScript on
  iOS), so a UIKit port would keep only the enumeration/lookup/branch-resolution
  logic as a plain Swift type for use by, for example, a debug menu or a
  Shortcuts (App Intents) integration — `objectSpecifier` and the
  `applicationElementSpecifier`-keyed addressing have no iOS analogue.
- **WinUI 3**: There is no AppleScript/Cocoa Scripting equivalent on
  Windows; the nearest analogue for "let external automation enumerate and
  address open windows, tabs and panes" is exposing a small COM Automation
  or Windows App SDK scripting surface, or simply a public API other in-process
  code calls directly. Port the three enumerations as plain C# properties
  (`IReadOnlyList<ScriptableProjectWindow>` etc.) computed fresh on every
  access from whatever collection tracks open project windows (mirror
  `openWindowControllers`'s already-recorded open-order list rather than a
  `Dictionary`'s enumeration order, which .NET does not guarantee stable
  either). Port the three id-based lookups as `FirstOrDefault` over a LINQ
  `SelectMany`, which is lazy by default and so preserves the short-circuit
  behavior of **window-lookup-short-circuits**/**tab-lookup-short-circuits**/**pane-lookup-short-circuits**
  without extra effort. Mirror the weak-vs-strong asymmetry with
  `WeakReference<ComposableTabsWindowController>` for the window a
  `ScriptableProjectWindow`-equivalent holds and a plain strong reference for
  the pane view model a `ScriptablePane`-equivalent holds. Resolve the git
  branch through the same `GitClient`/`BranchController` port this family's
  siblings already define (see
  `adtoolkit://cookbook/workspace/projects/branch-controller`), folding
  a `null` result to `string.Empty` at the same point `ComposableTabsWindowController.scriptingTabs(branch:)`
  does, and enforce main-thread confinement with `DispatcherQueue` in place
  of `@MainActor`.

