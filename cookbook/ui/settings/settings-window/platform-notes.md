
- **SwiftUI**: build the two-pane shape as a `NavigationSplitView` with a
  `List(selection:)` sidebar (sorted alphabetically to match
  `sortsPanelsByTitle`) and a `.searchable` modifier for the sidebar search.
  `NavigationSplitView`'s selection model has no back/forward concept, so
  that has to be rebuilt explicitly: a small observable object exposing
  `canGoBack`/`canGoForward` and a small history stack, driving two
  `.toolbar` `Button`s. The panel-title toolbar item becomes a
  `.principal`-placement `Text` (or the detail column's `.navigationTitle`
  read back into the toolbar), and the help toggle is a `.toolbar` button
  bound to `@State private var isHelpVisible`, swapping
  `Image(systemName:)` between `"questionmark.circle"` and
  `"questionmark.circle.fill"`.
- **Compose (Desktop/Android)**: model the window as one top-level
  composable with a `Row` of a `LazyColumn` sidebar (Material 3
  `NavigationRail`/`PermanentDrawerSheet`, alphabetically sorted, with a
  search `TextField` at its top) and a detail pane. Compose Navigation's
  back stack does not map directly to a two-pane split's back/forward, so
  mirror it with a small view-model exposing `canGoBack`/`canGoForward`
  booleans backing two `IconButton`s in the top app bar. The help toggle
  maps to an `IconToggleButton` swapping between an outlined and a filled
  help icon, tinted via `MaterialTheme.colorScheme.secondary`/`primary`.
- **React/Web**: a two-pane layout (`<nav>` sidebar + `<main>` detail);
  because browser back/forward already exists at the tab level, the
  in-window back/forward here maps to two `<button>` elements bound to
  `disabled={!canGoBack}` / `disabled={!canGoForward}` state, not to
  `history.back()`. The help toggle is a `<button aria-pressed={isOpen}>`
  swapping an inline SVG icon and its `title` attribute, opening the help
  drawer as a `role="complementary"` panel or a `<dialog>`.
- **AppKit / UIKit**: this is the source platform, and it is AppKit-only —
  no UIKit counterpart exists in source. The window is an `NSWindow`; its
  title text (`windowTitle`, mapped to AppKit's `title`) is hidden via
  `titleVisibility = .hidden`. The full-height-sidebar style mask is
  `[.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]`.
  The hosted split view's neutral properties map to `sidebarTitle = nil`,
  `showsSidebarSearch = true`, `sortsPanelsByTitle = true`; the panel-list
  property (`settingPanels`) forwards to `viewController?.panels` /
  `viewController?.setPanels(_:)`, returning `[]` before the split loads.
  `activatesOnShow` is the open, overridable `Bool` (default `true`); when
  `false`, `showWindow()` calls `super.showWindow()` and returns without
  calling `NSApp.activate` or making the window key. A host commonly
  overrides it to `false` for an `LSUIElement`/menu-bar-only host. Under
  `QuietWindowPresentation.isEnabled`, `showWindow()` calls
  `window?.makeKeyAndOrderFrontQuietly()`; otherwise it calls
  `NSApp.activate(ignoringOtherApps: true)` then
  `window?.makeKeyAndOrderFront(nil)`. `configureWindow(_:)` builds a
  `HelpDrawerController(parentWindow:)` as the split's `helpPresenter`,
  installs an `NSToolbar` identified `"ComposableSettings.Toolbar"`
  (`displayMode = .iconOnly`, `allowsUserCustomization = false`), sets
  `toolbarStyle = .unified`, `titlebarAppearsTransparent = true`,
  `titlebarSeparatorStyle = .none`, and sets `showsInlineHelpButton = false`.
  `toolbarDefaultItemIdentifiers`/`toolbarAllowedItemIdentifiers` both
  return `[.sidebarTrackingSeparator, .settingsNavigation,
  .settingsPanelTitle, .flexibleSpace, .settingsHelp]`. The navigation
  control is one momentary, `.separated`-style `NSSegmentedControl` with two
  segments — `chevron.backward` labeled "Back" and `chevron.forward`
  labeled "Forward" — wired so segment `0` calls `goBack()`, segment `1`
  calls `goForward()`, and any other value including `-1` calls neither;
  enablement syncs from `canGoBack`/`canGoForward` on every
  `onNavigationChange`, because a custom-view toolbar item receives no
  AppKit validation pass. The panel-title item is a `ThemedLabel`
  (`NSTextField` subclass) reading `currentPanelTitle ?? ""`, non-editable,
  `.heading` text role, `.primaryText` color role,
  `lineBreakMode = .byTruncatingTail`, horizontal content-hugging
  `.defaultHigh` — its font comes from `SemanticPalette.font(_:)`. The help
  control swaps `questionmark.circle`/`questionmark.circle.fill` SF Symbols
  (`NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)`, applied
  in `WindowToolbarBuilder.applyDisclosureAppearance`), tints via
  `contentTintColor` between `secondaryTextColor`/`accentColor`, and keeps
  its image's `accessibilityDescription` fixed at `"Help"` (identifier
  `"ComposableSettings.help"`, set by `WindowToolbarBuilder.iconButtonItem`)
  across tooltip swaps ("Show Help"/"Hide Help"). Its live reference,
  `ThemePaletteObserver` theme tracking, and
  `helpPresenter?.helpAnchorView` assignment are wired only when the
  toolbar factory's `willBeInsertedIntoToolbar` flag is `true`, never for
  the customization-palette sample or a rebuild pass. Clicking it calls
  `viewController?.toggleHelp()`. The sidebar tracking separator is an
  `NSTrackingSeparatorToolbarItem` bound to `viewController?.splitView` at
  divider index `0`, `nil` if there is no split view. The navigation,
  panel-title, and help items each set `visibilityPriority = .high`; the
  toolbar item factory returns `nil` for any `NSToolbarItem.Identifier`
  outside that fixed list. The private `updateToolbarState()` method is
  what couples the help button's refresh to navigation changes: it is the
  shared refresh path behind both **syncs-navigation-control-enablement**
  and **updates-help-glyph-on-navigation-change**, called from the
  `onNavigationChange` closure installed in `installToolbar(on:)`. The
  class and its methods are `@MainActor`-isolated (as is its
  `WindowController` superclass); no explicit reentrancy guard is installed
  because every entry point (`showWindow()`, the toolbar delegate methods,
  the two button actions) runs to completion synchronously. The window's
  background color is set once, at window creation, by the inherited
  `SingleWindowController.loadWindow()`, to
  `ThemePaletteObserver.currentPalette.windowBackgroundColor`. Window
  sizing comes from the inherited `SingleWindowController`/`WindowManager`
  machinery (default 600×480pt absent a registered `WindowSpec` for the
  `"settings"` id). None of this file's user-facing string literals pass
  through `NSLocalizedString` or a String Catalog lookup; no
  `Logger`/`os_log`/print-based logging call appears anywhere in the file;
  no `NSUserActivity`/URL-scheme handling exists — the window opens only
  via direct `showWindow()` calls. Files: this file (`SettingsWindow.swift`),
  `SplitViewController.swift` (sidebar/detail split, search, navigation
  history — a separate ingredient), `ComposableSettingsPanel.swift` /
  `SettingsPanelViewController.swift` (the per-panel contract — a separate
  ingredient), `Help/HelpDrawerController.swift` (the deprecated
  `NSDrawer`-backed help presenter), `WindowToolbarBuilder.swift`
  (icon-button construction and the disclosure-glyph helper),
  `SingleWindowController.swift` / `WindowController.swift` (window
  lifecycle and frame persistence), `ThemedViews.swift` (`ThemedLabel`), and
  `QuietWindowPresentation.swift` (test/automation activation suppression).
- **WinUI 3**: the closest native shape is a single `Window` hosting a
  `NavigationView` in `Left` or `LeftCompact` `PaneDisplayMode` as the
  sidebar, with `NavigationView.MenuItems` sorted alphabetically to match
  `sortsPanelsByTitle` and `NavigationView.AutoSuggestBox` set to reproduce
  `showsSidebarSearch`, and a `Frame` in the content area navigating between
  per-panel `Page`s. `NavigationView` supplies its own back button
  (`IsBackButtonVisible`) but nothing for forward, so forward needs two
  custom `AppBarButton`s in the window's `TitleBar`/`CommandBar`, bound to a
  small navigation-history view-model exposing `CanGoBack`/`CanGoForward` to
  mirror `canGoBack`/`canGoForward`. Put the panel-title `TextBlock` in that
  same `CommandBar`, bound to `Frame.CurrentSourcePageType`'s title.
  `Window.ExtendsContentIntoTitleBar = true` plus
  `Window.SetTitleBar(commandBar)` reproduces
  `.fullSizeContentView` + `titlebarAppearsTransparent` +
  `titleVisibility = .hidden` together. The help toggle is an
  `AppBarToggleButton` swapping a `FontIcon`/`SymbolIcon` between an
  outline and filled help glyph via its `IsChecked` state, driving a
  `SplitView` (`DisplayMode="Inline"` or `"CompactOverlay"`) pinned to the
  window's trailing edge as the WinUI substitute for the AppKit help
  drawer — WinUI has no drawer primitive of its own, so `SplitView` is the
  standard stand-in, matching the pattern
  `adtoolkit://cookbook/ui/layout/composable-tabs/tabs-window` already uses
  for its own drawer translation.

