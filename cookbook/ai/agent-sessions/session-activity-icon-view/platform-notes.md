
- **SwiftUI**: Compose a small `View` wrapping `Image(systemName:)` sized to
  a fixed `13x13` frame, choosing the symbol name and a
  `.symbolRenderingMode(.monochrome).foregroundStyle(tint)` the same way
  `symbolName`/`applyTheme` switch here (SwiftUI's own single-fill monochrome
  mode reproduces the `.sourceAtop` fill trick without hand-rolling it).
  Drive the spin with `.rotationEffect` inside
  `.animation(.linear(duration: 1.1).repeatForever(autoreverses: false))`
  and the pulse with `.opacity` inside
  `.animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true))`,
  and gate both behind `@Environment(\.accessibilityReduceMotion)` — the
  concrete fix for the Reduce Motion gap noted above. Toggle visibility with
  a conditional view rather than `isHidden` so a `Group`/stack containing it
  collapses the same way the AppKit stack does when it is hidden.
- **Compose**: Start from an `Icon` inside a `Modifier.size(13.dp)` box,
  wrapped in `AnimatedVisibility` for the idle-and-not-summarizing hide.
  Drive the spin with `rememberInfiniteTransition` animating
  `Modifier.graphicsLayer { rotationZ = angle }` linearly over 1100ms, and
  the pulse with a second `rememberInfiniteTransition` animating
  `Modifier.alpha` between 1f and 0.25f with a `RepeatMode.Reverse` tween
  over 700ms; read the system's reduced-motion signal
  (`Settings.Global.ANIMATOR_DURATION_SCALE` or the platform's accessibility
  API) before starting either, mirroring the Reduce Motion gap noted above.
  Map the three theme tints to `MaterialTheme.colorScheme` roles (e.g.
  `primary` for accent, `onSurfaceVariant` for tertiary text, `error` or a
  custom warning role for warning).
- **React/Web**: Render the glyph as an inline SVG or icon-font element
  inside a fixed `13px × 13px` box, toggling `display: none` for the
  idle-and-not-summarizing state so the row collapses around it the way the
  AppKit stack does when the view is hidden. Drive the spin with a CSS
  `@keyframes` rule animating `transform: rotate(...)` linearly over 1.1s,
  infinite, and the pulse with a `@keyframes` rule animating `opacity`
  between 1 and 0.25 over 0.7s per direction (`animation-duration: 0.7s` with
  `alternate`, so a full up-and-back cycle is 1.4s), infinite — both wrapped in
  `@media (prefers-reduced-motion: reduce)` guards, the concrete fix for the
  Reduce Motion gap noted above. Use `role="img"` and `aria-label` for the
  four state strings, and re-render the fill color from CSS custom
  properties bound to the active theme rather than hardcoding it.
- **AppKit / UIKit**: Source at
  `packages/apple/AgenticToolkit/macOS/Features/SessionWatcher/SessionListWindow/SessionWatcherActivityIconView.swift`
  (this recipe's source): `SessionWatcher.SessionWatcherActivityIconView`, a
  nested type implemented as a `final` `NSView` subclass conforming to
  `Themeable`, drawing into a private `CALayer` sublayer rather than the
  view's own backing layer, specifically to avoid AppKit re-centering the
  view's own layer's anchor point on every frame change (see Design
  Decisions). Its fixed 13pt size is `Self.side`, enforced via a required
  horizontal content-compression-resistance priority
  (`setContentCompressionResistancePriority(.required, for: .horizontal)`).
  The four glyphs are SF Symbols: `sparkles`, `arrow.triangle.2.circlepath`,
  `circle.fill`, and `exclamationmark.circle.fill`, looked up via
  `NSImage(systemSymbolName:accessibilityDescription:)`; when that lookup
  returns `nil` the glyph layer's `contents` is set to `nil`. Displayed state
  is pushed in through `update(activity:isSummarizing:)`; the pre-theme
  fallback tint is `NSColor.tertiaryLabelColor` until `applyTheme(_:)` is
  first called. It satisfies **symbol-layer-distinction** by drawing the raw
  SF Symbol image and then filling the tint color over it with
  `.sourceAtop` compositing (see Design Decisions), rather than an
  `NSImage.SymbolConfiguration` color option; it satisfies
  **glyph-bounds-layout** by wrapping each layout pass's `bounds`/`position`
  assignment in a `CATransaction` with `setDisableActions(true)`, so no
  implicit layer animation plays for the resize/reposition; it satisfies
  **display-scale-rerender** by reading `backingScaleFactor` from the view's
  window, falling back to `NSScreen.main`, falling back to `2`; and it
  satisfies **programmatic-construction-only** by marking `init?(coder:)`
  `@available(*, unavailable)` and having it `fatalError()`. A UIKit port
  replaces `NSView`/`NSColor`/`NSImage` with `UIView`/`UIColor`/`UIImage`,
  uses `CALayer` sublayer animation the same way, and must re-derive
  `viewDidMoveToWindow`'s "animations are dropped when leaving a window"
  handling and `viewDidChangeBackingProperties`'s scale handling from
  `traitCollectionDidChange`/`UIScreen.scale`, since this source's window-
  and appearance-observing overrides are AppKit-specific. Substitute
  `UIAccessibility.isReduceMotionEnabled` for the Reduce Motion check this
  source lacks. Public surface:
  ```swift
  public init(activity: SessionWatcherActivity, isSummarizing: Bool)
  public func update(activity: SessionWatcherActivity, isSummarizing: Bool)
  public func applyTheme(_ palette: SemanticPalette)
  ```
- **WinUI 3**: Start from a `FontIcon` (or a small `Viewbox` wrapping a
  `PathIcon`) inside a fixed `Width="13" Height="13"` container, since WinUI
  3 has no single control that both switches glyph *and* spins/pulses
  on demand the way this source's `CALayer` does — `ProgressRing`/`ProgressBar`
  are indeterminate-progress controls, not arbitrary-glyph animators.
  Bind `Visibility` to a converter reproducing
  **idle-visibility-suppression**, and bind the icon's
  `Foreground` `SolidColorBrush` to theme resources matching the three
  tints (e.g. `AccentTextFillColorPrimaryBrush` for accent,
  `TextFillColorTertiaryBrush` for tertiary text, `SystemFillColorCautionBrush`
  for warning). Drive the spin with a `Storyboard` containing a
  `DoubleAnimation` on a `RotateTransform.Angle` from 0 to 360 over
  `Duration="0:0:1.1"` with `RepeatBehavior="Forever"`, and the pulse with a
  `DoubleAnimation` on `Opacity` from 1.0 to 0.25 with `AutoReverse="True"`
  and `RepeatBehavior="Forever"` over `Duration="0:0:0.7"`. Check
  `new Windows.UI.ViewManagement.UISettings().AnimationsEnabled` before
  starting either `Storyboard`, mirroring the Reduce Motion gap noted
  above. Set `AutomationProperties.Name` to the same four state strings this
  source uses, and attach a matching `ToolTipService.ToolTip` for the visual
  tooltip.

