
- **SwiftUI**: Nest an inner `NavigationSplitView` as the detail content of
  an outer `NavigationSplitView`'s selected row. Give the inner split's
  sidebar column a fixed
  `.navigationSplitViewColumnWidth(min: w, ideal: w, max: w)` (min == ideal
  == max), the nearest SwiftUI analog to the content-sized-sidebar flag's
  non-draggable, content-sized sidebar, and title it from the same
  descriptor's title used for the outer row's own label. There is no
  direct SwiftUI equivalent of a per-split detail-pane minimum thickness;
  the nearest approximation is a `.frame(minWidth:)` on the inner split's
  detail content.
- **Compose**: Nest a two-pane `ListDetailPaneScaffold` (Material 3
  adaptive) or a `PermanentNavigationDrawer` inside an outer one of the
  same shape; size the inner pane with `Modifier.width(IntrinsicSize.Max)`
  rather than a draggable `Modifier.width` handle, mirroring the fixed
  sidebar. Reuse the same descriptor title for both the outer list row's
  label and the inner pane's own header.
- **React/Web**: A nested two-column layout (`display: grid;
  grid-template-columns: max-content 1fr`) inside an outer layout of the
  same shape, so the inner nav column sizes to its widest row with no
  resize handle — the web analog of the content-sized-sidebar flag. Reuse
  the same title string for the outer link and the inner column's
  heading.
- **AppKit / UIKit** (source platform): Source file
  `SettingsPanelSplitViewController.swift`, AppKit-only, no UIKit
  counterpart in this codebase (`ComposableSettingsWindow/` is entirely
  AppKit). It subclasses `ComposableSettings.SplitViewController`
  (`SplitViewController/SplitViewController.swift`), conforms to
  `ComposableSettingsPanel` (`ComposableSettingsPanel.swift`) through that
  inheritance, and stores a `ComposableSettings.SettingsPanelDescriptor`
  (`SettingsPanelDescriptor.swift`) — all three defined elsewhere in
  `AgenticToolkit` and not reimplemented here. The class is `@MainActor`,
  so construction and every property access are rejected off the main
  actor at compile time. It does not support construction via
  `init?(coder:)`: that initializer is overridden to call `fatalError()`,
  so a caller cannot construct one through that path. It also redeclares
  `helpContent`, `effectiveHelpContent`, and `searchKeywords` directly on
  the class rather than relying solely on `ComposableSettingsPanel`'s
  protocol-extension defaults — see Design Decisions for why.
- **WinUI 3**: Nest one `NavigationView`
  inside another's `Content`. Give the inner `NavigationView`
  `PaneDisplayMode="Left"` and `IsPaneToggleButtonVisible="False"`; its
  built-in pane has no draggable splitter (unlike `SplitView`), which
  matches the content-sized-sidebar flag without extra work. Bind the
  inner `NavigationView`'s `Header` to the panel's own title — the WinUI
  analog of setting the sidebar title from the descriptor's title — and
  set the *outer* `NavigationViewItem` that hosts this nested view's
  `Content` from that same title string. WinUI has no per-pane analog of
  a minimum-thickness floor; approximate the `200`pt floor with a fixed
  `MinWidth="200"` on the `Frame`/`ContentPresenter` hosting the inner
  `NavigationView`'s content region, deliberately smaller than the outer
  shell's own minimum width so it constrains only the nested region. For
  help, forward whichever inner `NavigationViewItem` is selected up to the
  outer shell's single help affordance (a `Button` + `Flyout`, or
  `AutomationProperties.HelpText`) and fall back to this nested view's own
  help text only when the inner selection offers none — mirroring the
  effective-help-content fallback chain.

