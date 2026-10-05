
- **SwiftUI**: Compose a `VStack(alignment: .leading, spacing: 20)` inside a
  container padded `.padding(.top, 20).padding(.horizontal, 20)`, with the
  bottom left to the stack's own intrinsic height rather than a fixed
  `.padding(.bottom, 20)` pin — SwiftUI's default layout already lets
  content fall short of an oversized parent, mirroring
  **bottom-inset-inequality**. Give the container a `.background` filled
  from the theme's window-background token, matching
  **construction-time-background-paint**/**theme-change-background-repaint**,
  which SwiftUI's environment-driven color already repaints automatically
  on a theme change with no manual observer. Insert an extra
  `Spacer().frame(height: 10)` immediately before a heading view — 10pt
  plus the `VStack`'s own 20pt `spacing` totals the 30pt of **heading-gap**
  — but only when a view already precedes it, mirroring
  **empty-stack-spacing-skip**.
- **Compose**: Use a `Column(verticalArrangement =
  Arrangement.spacedBy(20.dp), horizontalAlignment = Alignment.Start,
  modifier = Modifier.padding(start = 20.dp, end = 20.dp, top =
  20.dp).background(<windowBackground token>))`, letting the column wrap its
  content height rather than filling a fixed-height parent, the Compose
  analog of the inequality bottom constraint. Precede a heading composable
  with an extra `Spacer(Modifier.height(10.dp))` (10dp + the column's own
  20dp gap = 30dp) only when it is not the column's first child, mirroring
  **heading-gap**/**empty-stack-spacing-skip**.
- **React/Web**: A `<div>` styled `display: flex; flex-direction: column;
  align-items: flex-start; gap: 20px; padding: 20px 20px 0 20px;
  background: var(--window-background)`, sized to its content rather than a
  fixed height so it can fall short of a taller parent, mirroring
  **bottom-inset-inequality**. Give a heading element `margin-top: 10px` in
  addition to the flex `gap` (10px + 20px = 30px total) only when a previous
  sibling exists (a `:not(:first-child)` selector), mirroring the
  conditional spacing rule; rely on the CSS custom property's own value
  updating on a theme class/attribute change for
  **theme-change-background-repaint**.
- **AppKit / UIKit** (source platform): `ComposableSettings.PanelView`, at
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/PanelView.swift`,
  is a macOS-only (`import AppKit`), `open`, `@MainActor` `NSView` subclass
  conforming to `SettingsViewProtocol` (a marker protocol with no
  requirements of its own). Internally, the private stored properties
  `stackView` (`NSStackView`) and `themeObserver`
  (`ThemePaletteObserver?`) back the stack and theme-repaint behavior
  described under Behavioral Requirements; `themeObserver` is retained in
  a stored property for the view's whole lifetime so its Combine
  subscriptions are not deallocated early. `wantsLayer = true` is set at
  construction so `layer?.backgroundColor` can be painted
  (**construction-time-background-paint**), reading the current theme's
  `.windowBackground` role (`palette.windowBackgroundColor.cgColor`),
  resolved through a `ThemePaletteObserver` constructed with `host: self`
  (see Design Decisions) rather than the unscoped, app-wide palette; the
  observer repaints the layer on every subsequent notification
  (**theme-change-background-repaint**). The component and its internal
  stack view each set `translatesAutoresizingMaskIntoConstraints = false`
  at construction — a pure Auto Layout framework construction rule with no
  equivalent step needed on a platform that never had a legacy
  autoresizing-mask/frame layout system to opt out of. The public
  `convenience init()` forwards to `init(frame: .zero)` with no parameters
  of its own; `required init?(coder:)` traps via `fatalError`
  (**rejects-deserializing-construction**), with message text `not
  overridden` (see Design Decisions — the mismatch with the sibling
  `GroupView`/`PanelHeadingView` message is a known, unsmoothed
  inconsistency). The add-heading operation is `@discardableResult`, built
  on `NSStackView` and Auto Layout. There is no UIKit code path in source;
  because `ThemePaletteObserver` itself is already cross-platform
  (`SourcesUI/Shared`), a UIKit port would only need to replace
  `NSStackView` with `UIStackView` and the layer background assignment
  with the UIKit equivalent (`layer.backgroundColor` on a layer-backed
  `UIView`, which is layer-backed by default) — the theme observer and its
  notification-driven repaint carry over unchanged.
- **WinUI 3**: Build a `StackPanel` (`Orientation="Vertical"`,
  `Spacing="20"`, matching **group-spacing**) inside a root whose
  `Background="{ThemeResource ApplicationPageBackgroundThemeBrush}"` (or the
  app's own window-background resource) repaints automatically through
  WinUI's `ThemeResource` re-resolution on a `RequestedTheme` change — the
  platform-native analog of
  **construction-time-background-paint**/**theme-change-background-repaint**,
  needing no manual observer equivalent to `ThemePaletteObserver`. Give the
  root `Padding="20,20,20,0"` and leave the `StackPanel`'s
  `VerticalAlignment` at its default `Top` rather than `Stretch`, so it
  sizes to its content and leaves slack below rather than stretching to
  fill the container — the WinUI analog of **bottom-inset-inequality**.
  Because `StackPanel.Spacing` cannot vary per-gap the way
  `NSStackView.setCustomSpacing(after:)` can, reproduce
  **heading-gap**/**empty-stack-spacing-skip** with an extra `<Border
  Height="10"/>` spacer element inserted immediately before a heading
  `TextBlock`/`StackPanel` — 10 plus the panel's own 20 `Spacing` totals the
  30 of `groupSpacing * 1.5` — but only when `Children.Count > 0` at the
  point of insertion.

