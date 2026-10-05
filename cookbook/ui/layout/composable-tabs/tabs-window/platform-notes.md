
- **SwiftUI**: not the source form. A SwiftUI rebuild would key a
  `WindowGroup`/`Scene` by project id for per-window state, with one
  `TabView`-like construct per enabled edge, all reading the same
  `[TabGroup]` model so a "project tab" still means one logical entry drawn
  on every enabled bar — SwiftUI's `TabView` has no native concept of
  multiple, independently dockable tab bars sharing one selection, so this
  would need a custom container rather than a bare `TabView`.
- **Compose (Android/Desktop)**: model the window as one
  `Activity`/`ComposeWindow`; represent each enabled edge as a `TabRow` (top)
  or a side rail composable (left/right) or a bottom bar, all driven by one
  shared `[TabGroup]`-equivalent state holder in a `ViewModel`; the
  250ms focused-leaf debounce and the persist-on-structural-change split map
  onto `SavedStateHandle` writes gated the same way.
- **React/Web**: the window becomes a page or route; each edge's tab strip
  is a component reading from one shared tab-groups store (Redux/Zustand);
  the toolbar search field maps to an `<input type="search">` wired to
  whichever pane component is currently "the search target," mirroring the
  window's search-target tracking; window-frame persistence has no web
  equivalent (the browser owns window chrome) and would be dropped, keeping
  only the tab-layout and drawer-preference persistence.
- **AppKit / UIKit**: this is the source platform, and it is AppKit-only —
  no UIKit counterpart exists in source. The window is a `@MainActor`
  `NSWindowController` (`ComposableTabsWindowController`); every
  requirement above holds only under main-actor confinement, which is why
  there is no defined cross-thread behavior in Edge Cases: the three
  reentrancy guards named there are the boolean properties
  `isReloadingTabs`, `isMirroringArrangement`, and `isClosing`. The window's
  identifier is derived by `ComposableTabsWindowController.windowID(for:)`;
  its geometry persistence is configured via
  `WindowSpec(persistsFrame: true, minSize: NSSize(width: 400, height: 300), ...)`
  and stored through `WindowManager.shared.frames`
  (`WindowFrameManager.clearSavedState(for:)` clears it). Standard window
  controls are configured via
  `windowStyleMask = [.titled, .closable, .resizable, .miniaturizable]`.
  The toolbar's unified appearance is `toolbarStyle == .unified`. The
  settings titlebar button presents `ComposableTabsSettingsViewController`
  as a sheet on the window's content view controller. Search-target
  tracking (`searchTargetNodeID`) is recomputed by
  `applySearchAvailability(to:)`, called from tab activation, an
  active-pane notification, and `showWindow(_:)`. Tab-activation focus
  restoration is deferred by one run-loop turn so the tab's view hierarchy
  is mounted first. Pane enumeration (`allPanes()`) walks `Edge.allCases`
  order (`top`, `right`, `bottom`, `left`); the enabled-edge setter is
  `enabledTabEdgeNames`; the reload operation is `reloadTabs()`. The help
  glyph is the SF Symbol pair `questionmark.circle` (outlined) /
  `questionmark.circle.fill` (filled); the arrange toggle's pressed-looking
  active state is `NSButton.state` (`.on`/`.off`), rendered by AppKit as a
  pressed bezel on a `.texturedRounded` button, in addition to accent
  tint. Chrome colors track `ThemePaletteObserver.currentPalette` (its
  `windowBackgroundColor`, `projectPaneBackdrop`, `projectPaneOutline`).
  Content insets are `PaneSpacing.contentInsets`
  (`UserSetting<Int>` values `pane_spacing_top`/`_leading`/`_bottom`/
  `_trailing`); the side-bar start-inset arithmetic uses
  `ComposableTabsPaneBackgroundView.borderInset` (2pt) and
  `PaneTitleBarView.height` (26pt). The `project` configuration option is
  typed `ProjectWorkspace`; `tabItemDataSource` is typed
  `ComposableTabsTabItemDataSource?`; persisted tab layout is a
  `TabRecord` list, written via `project.persistTabs(...)` and
  `project.setSetting(_:to:)`, gated by the `hasDisclosedHelp` flag for the
  drawer's tab/width settings. No `NSLocalizedString`/string-catalog lookup
  exists in source for any of this file's literals. Files: this file
  (`ComposableTabsWindowController.swift`), `PaneSpacing.swift`,
  `ComposableTabsPaneViewController.swift` (for `titleBarBottom`),
  `SingleWindowController.swift` / `WindowController.swift` /
  `WindowSpec.swift` (window lifecycle and geometry persistence),
  `WindowToolbarBuilder.swift` (toolbar items and the disclosure-glyph
  helper), `Edge.swift`, `ComposableTabsTabItemDataSource.swift`, and
  `LayoutNode.swift` (`TabRecord`).
- **WinUI 3**: the closest native shape is a single `Window` whose primary
  edge uses `Microsoft.UI.Xaml.Controls.TabView` — WinUI 3's `TabView` only
  docks along the top, so the other three edges (right/bottom/left) have no
  built-in equivalent and need a custom `ItemsRepeater`/`ListView` styled as
  a side or bottom tab strip, all bound to one shared tab-group view-model
  list so a "project tab" still means one logical entry represented on every
  enabled strip. Persisted window geometry maps to `AppWindow.Resize`/`Move`
  saved to `ApplicationData.LocalSettings` keyed by project id, mirroring
  the source's derived window identifier. There is no WinUI drawer primitive
  for the help panel; use a `SplitView` in `Inline` or `CompactOverlay`
  display mode pinned to a window edge, with `IsPaneOpen`/`OpenPaneLength`
  bound to the same per-project `drawer.open`/`drawer.width` settings keys,
  written only after first disclosure exactly as the source's disclosure
  flag gates it. The unified toolbar's search field maps to an
  `AutoSuggestBox` in the window's `TitleBar`/`CommandBar`, toggling
  `IsEnabled` the same way the search field's enabled state is toggled in
  source; the arrange and settings buttons map to two `AppBarButton`s in a
  `CommandBar`, with the arrange toggle using an `AppBarToggleButton`'s
  `IsChecked` visual state in place of the source's tint-plus-button-state
  combination.
- **UI-thread confinement**: `confines-to-ui-thread` — the window controller is declared `@MainActor`, so use from off the main actor fails to compile.

