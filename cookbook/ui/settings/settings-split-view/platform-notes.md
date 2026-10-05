
- **SwiftUI**: Use `NavigationSplitView` with a `List` (built from the
  panel list) as the sidebar column and the selected panel's view as the
  detail column. For a content-sized sidebar, set the sidebar column's
  `.navigationSplitViewColumnWidth(min:ideal:max:)` to the same fixed
  value (min == ideal == max), the nearest SwiftUI analog of a pinned,
  non-draggable width; for the draggable default, use `min: 160, ideal:
  <persisted>, max: 360` and persist the ideal width yourself (SwiftUI has
  no built-in per-split autosave equivalent to a native width-persistence
  mechanism). Use `.searchable(text:)` on the sidebar for the
  search-enabled option, and drive back/forward with a small custom index
  stack, since `NavigationSplitView` has no built-in in-place trail
  matching this component's discard-forward-on-new-step semantics.
- **Compose**: Compose a two-pane `ListDetailPaneScaffold` (Material 3
  adaptive) or a manual `Row` of a fixed-width `LazyColumn` sidebar plus a
  weighted detail `Box`. Size the sidebar with
  `Modifier.width(IntrinsicSize.Max)` for the content-sized case, or a
  draggable divider whose width is saved to `DataStore`/`SharedPreferences`
  (mirroring the persistence) for the default case. Filter the list with
  an `OutlinedTextField` bound to a `mutableStateOf` query; implement
  back/forward as a small `MutableList<Int>` index trail, since Compose
  Navigation's back stack tracks destinations, not row selections within
  one screen.
- **React/Web**: A CSS Grid two-column layout
  (`grid-template-columns: <sidebar> 1fr`), sidebar `<nav>` of `<button>`s
  or links, detail `<main>`. For the content-sized case, size the sidebar
  column `max-content`; for the draggable default, add a resizer handle
  that persists its width to `localStorage` under a key analogous to the
  sidebar persistence key. Filter with a controlled `<input
  type="search">`; implement back/forward as an in-memory index stack
  rather than the browser History API, since each panel is not
  necessarily its own route.
- **AppKit / UIKit** (source platform): Source file
  `SplitViewController.swift` (`ComposableSettingsWindow/SplitViewController/`),
  AppKit-only — an `NSSplitViewController` subclass of `ThemedSplitViewController`,
  composing a `PanelListViewController` sidebar item and a `PanelHostView`-hosted
  detail item, wrapping non-self-scrolling panel content in a
  `PanelScrollView`, and tracking navigation with a
  `SettingsNavigationHistory` value type. The class is `@MainActor`, so
  construction and every property access are rejected off the main actor
  at compile time. It does not support construction via `init?(coder:)`:
  that initializer is `@available(*, unavailable)` and its body is
  `fatalError()`. `panels` is declared `private(set)`, enforcing
  **exposes-hosted-panels-read-only** at compile time. The sidebar item's
  `holdingPriority` is `.defaultLow + 1` against the detail item's
  `.defaultLow`, which is how **prioritizes-detail-pane-on-resize** is
  implemented. `currentPanel` is computed by reading
  `detailContainer.children.first`, and `enclosingSettingsSplit` walks
  `parent` upward looking for the nearest
  `ComposableSettings.SplitViewController` — the mechanisms behind
  **reports-current-panel-from-detail-container** and
  **locates-enclosing-split-by-parent-chain**. No UIKit counterpart exists
  in this codebase (`ComposableSettingsWindow/` is entirely AppKit); a
  UIKit port would reach for `UISplitViewController` with `.doubleColumn`
  style, though it has no analog of the content-sized-sidebar flag's
  pinned min==max thickness or of `NSSplitView`'s dragging-based
  `autosaveName` persistence.
- **WinUI 3** (the reason this recipe exists): Use a `NavigationView` with
  `PaneDisplayMode="Left"` as the sidebar and its `Content`/`Frame` as the
  detail region. Bind `MenuItems` to the panel list — one
  `NavigationViewItem` per panel, grouped under a `NavigationViewItemHeader`
  per section run, mirroring the panel list's section grouping — and
  drive selection through `SelectionChanged` (analogous to the panel
  list's own selection callback). For the draggable default
  (content-sized-sidebar flag `false`), set
  `IsPaneToggleButtonVisible="False"` and bind `OpenPaneLength` to a value
  restored from `ApplicationData.LocalSettings` keyed by the sidebar
  persistence key, constrained to a `160`–`360`-equivalent range; for a
  content-sized sidebar, fix `OpenPaneLength` to the pane's measured
  content width and skip persistence entirely, exactly as this component
  does. There is no WinUI analog of a per-item content-side minimum
  thickness, so approximate the detail-minimum-thickness floor (and the
  raised nested-sibling floor) with a `MinWidth` on the
  `Frame`/`ContentPresenter` hosting `Content`. For search, add an
  `AutoSuggestBox` as `NavigationView.PaneCustomContent`, wire
  `TextChanged` to filter `MenuItems.Source` the way this component's
  search-query change filters the panel list, and forward the list's
  Up/Down `KeyDown` to move `SelectedItem` while the `AutoSuggestBox`
  keeps focus — mirroring the arrow-key redirect. Implement back/forward
  with two `Stack<int>`s alongside `NavigationView.BackRequested`, since
  this component's trail semantics (discard-forward-on-new-step, no-op on
  re-selecting the current row) have no built-in WinUI equivalent; for a
  nested `NavigationView` acting as a nested settings panel split does,
  forward whichever inner item is selected up to the outer shell's single
  help affordance, mirroring the effective-help/refresh-help outward
  chain.

