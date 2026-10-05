
- **SwiftUI**: Compose a `ZStack(alignment: .topTrailing)` with the
  swapped panel content as the base layer and a borderless `Button` as the
  overlay, offset `.padding(.top, 12).padding(.trailing, 12)`. Drive the
  button's `Image(systemName:)` between `"questionmark.circle.fill"` and
  `"questionmark.circle"`, and its `.foregroundStyle` between `.tint` and
  `.secondary`, from an observed `isHelpVisible` on whatever object plays
  the presenter's role; gate the button's presence on
  `showsHelpButton && helpPresenter != nil` the same way this view does.
  Content swap becomes whatever view a `@ViewBuilder`/enum-driven switch
  renders, since SwiftUI needs no manual subview teardown.
- **Compose**: A `Box` with the panel content filling it and an
  `IconButton` aligned `Alignment.TopEnd` with
  `Modifier.padding(top = 12.dp, end = 12.dp)`; swap between a filled and
  an outline "help" icon (e.g. `Icons.Filled.Help` /
  `Icons.Outlined.HelpOutline`) and between `MaterialTheme.colorScheme.primary`
  and `.onSurfaceVariant` tint from a `helpVisible: Boolean` state, and
  gate the button's presence on the same `showsHelpButton && helpPresenter
  != null` condition.
- **React/Web**: A relatively-positioned container `<div>` with the panel
  content as children and an absolutely positioned `<button>`
  (`position: absolute; top: 12px; right: 12px`) rendering an inline
  SVG/icon-font glyph that swaps between an outline and a filled variant;
  the button's `aria-label="Help"` stays fixed while a `title` attribute
  (or a tooltip component) swaps between "Show Help"/"Hide Help", mirroring
  the fixed-label/changing-tooltip split in source. CSS custom properties
  (or a theme context) supply the accent/secondary colors that swap with a
  `visible` boolean class or data attribute.
- **AppKit / UIKit** (source platform): Source at
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/PanelHostView.swift`
  (this recipe's source): a macOS-only (`import AppKit`), `@MainActor`
  `NSView` subclass. Specific to it: the manual subview teardown in
  `setContent(_:)` (`contentContainer.subviews.forEach { $0.removeFromSuperview() }`);
  the help button being added as a sibling of, and after, the content
  container so it always draws above swapped panels regardless of what
  they contain; the shared `NSView.pinToEdges(_:of:)` static helper
  (`ViewLayout.swift`) used for both the container's and the content
  view's edge constraints; the `buttonInset` constant (12pt) driving
  the button's own two constraints; and
  `translatesAutoresizingMaskIntoConstraints = false` set on the view
  itself, the content container, and the help button, per
  **constraint-based-layout-only**. The two icon variants are the SF
  Symbols `questionmark.circle.fill`/`questionmark.circle`, rendered via
  `NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)`
  (**help-button-symbol-configuration**); the tint is the button's
  `contentTintColor`, driven from the active `SemanticPalette`'s
  `accentColor`/`secondaryTextColor`, refreshed on change via a
  `ThemePaletteObserver` (**theme-change-refreshes-button-tint**). The
  button is a borderless (`isBordered = false`), image-only
  (`imagePosition = .imageOnly`), momentary-change (`setButtonType(.momentaryChange)`)
  `NSButton`, and `help-button-keyboard-focusable` is satisfied simply by
  never overriding `acceptsFirstResponder`, `keyDown`, or `performClick`,
  so `NSButton`'s stock key-view-loop and Space/Return activation apply
  unmodified. The three accessibility/tooltip strings are set as plain
  `String` literals through `setAccessibilityLabel(_:)`,
  `NSImage(systemSymbolName:accessibilityDescription:)`, and `toolTip` —
  none of these is a SwiftUI `Text`/`LocalizedStringKey` position, and no
  `NSLocalizedString` call or string-catalog reference appears anywhere in
  source. `init?(coder:)` is marked `@available(*, unavailable)` and traps,
  satisfying `rejects-deserializing-construction`. Whether help visibility
  is remembered across launches is decided by whichever presenter is
  assigned — for example `HelpDrawerController`'s own `UserSettings`-backed
  preference — entirely outside this file. On the minimum-tap-target
  question: this component targets macOS only, where controls are
  pointer-operated, and Apple's Human Interface Guidelines do not set a
  single numeric minimum hit-target size for a pointer-driven AppKit
  control the way they do for an iOS touch target (44×44pt); the button's
  actual click area comes from `NSButton`'s default cell sizing for this
  configuration, unmeasured and unoverridden here. A UIKit port would use a
  `UIView` overlaying a `UIButton(configuration: .plain())` pinned with
  `NSLayoutConstraint`s the same way, but no analogue currently exists
  elsewhere in this codebase's `ComposableSettingsWindow/` tree — the rest
  of it is AppKit-only.
- **WinUI 3**: Build this as a single-cell
  `Grid`: the swapped panel content (a `ContentControl` or `Frame` whose
  `Content` is reassigned the way `setContent(_:)` swaps subviews) fills
  the cell, and a borderless `Button` (`BorderThickness="0"`,
  `Background="Transparent"`, no `Style` resource applying a bezel) shares
  the same cell with `HorizontalAlignment="Right" VerticalAlignment="Top"
  Margin="0,12,12,0"` to match the 12px inset. The button's `Content` is a
  `FontIcon` bound to a Segoe Fluent Icons glyph; Segoe Fluent Icons has no
  built-in filled/outline question-mark pair the way SF Symbols does, so
  matching the source's filled-vs-outline distinction needs either two
  custom icon glyphs or a single glyph plus a `Fill`/`Stroke` visual-state
  swap — call this out as a deviation rather than a drop-in equivalent.
  Drive the two visual states with a `VisualStateManager`
  (`HelpHidden`/`HelpVisible`, swapping `Foreground` between
  `{ThemeResource AccentTextFillColorPrimaryBrush}` and
  `{ThemeResource TextFillColorSecondaryBrush}`) rather than imperative
  color assignment. Set `AutomationProperties.Name="Help"` (fixed, mirroring
  the source's static accessibility label) and bind `ToolTipService.ToolTip`
  to a string that swaps "Show Help"/"Hide Help" — WinUI's
  `AutomationProperties.Name` and `ToolTipService.ToolTip` are two separate
  properties, just as AppKit's accessibility label and `toolTip` are here,
  so the fixed-label/changing-tooltip split translates directly. Gate the
  button's `Visibility` on the same `showsHelpButton`-and-presenter
  condition used in source.

