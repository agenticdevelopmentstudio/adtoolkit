
- **SwiftUI**: Model each pane as a small view value exposing
  agent/model/session/directory/branch/summary/status plus `isFront: Bool`
  and `depth: Int`. Render the header as an `HStack` (agent `Text`, status
  `HStack` of small `Image(systemName:)`, `Spacer()`, close `Button`),
  reversing element order for the left edge with a conditional array rather
  than a mirrored layout direction, since only the close button's position
  changes, not the whole reading order. Drive fill/border/text color from
  `isFront` via `.foregroundStyle`/`.background`, and express recession as
  `.padding(edgeSet, CGFloat(min(depth, 3)) * 4)` on a vertical edge or a
  flat `4` on a horizontal one, wrapped in `withAnimation(.easeOut(duration:
  0.16))` gated on whether the view is already inserted into the hierarchy
  (mirroring the animates-when-attached check - an unattached view should
  set its position with no animation transaction at all). There is no
  direct SwiftUI equivalent of the one-point workspace overhang; approximate
  it with a `.padding(edge, -1)` applied to the card's background shape
  alone, not the whole view, so the overhang does not also push the text.
- **Compose**: Represent the pane as a `@Composable` taking the same data
  plus `isFront`/`depth` state. Build the header as a `Row` with
  `Arrangement.SpaceBetween`, reversing only the close button's position for
  a left-edge-equivalent layout with a conditional element order, not a
  mirrored `LayoutDirection.Rtl`, since only the close button's position
  changes, not the whole reading order. Animate recession with
  `animateDpAsState(targetValue = ..., animationSpec = tween(160, easing =
  LinearOutSlowInEasing))` applied to a `Modifier.padding` or
  `Modifier.offset`, mirroring the ease-out timing curve. Because Compose's
  `border` modifier always strokes all four sides, reproduce the open-sided
  outline with a custom `Modifier.drawWithContent` that strokes only the
  three non-workspace-facing sides via a hand-built `Path`, exactly as the
  card's own path-tracing skips the fourth side.
- **React/Web**: Render the card as a `<div>` with CSS custom properties for
  background/border color toggled by a `data-front` attribute, and a header
  using `display: flex; justify-content: space-between`, reversing only the
  close button's position for a left-edge-equivalent layout with a
  conditional DOM order, not `flex-direction: row-reverse` on the whole
  header, since only the close button's position changes, not the whole
  reading order. Animate the recession with a `transition: inset 160ms
  cubic-bezier(0, 0, 0.58, 1)` (ease-out) on `inset`/`transform:
  translate(...)`, applied only once the element is mounted (a freshly
  mounted card sets its initial inset with no transition class, mirroring
  the no-animation-when-detached case). Reproduce the three-sided open
  outline with individual `border-top`/`border-right`/`border-bottom`/
  `border-left` declarations instead of the `border` shorthand, omitting the
  workspace-facing side.
- **AppKit / UIKit** (source platform): Source lives in
  `TabPaneViewController.swift` (controller: identity, data-source-driven
  `reload()`, `TabBarStackedItem` conformance, `applyDepth()` reconciling
  selection with depth) and `TabPaneView.swift` (the visual card: geometry
  constants, `CardSides`/`InsetBox` inset math, `TabCardBackgroundView`'s
  open-path fill/stroke, and the `NSAnimationContext`-driven move). This is
  AppKit/macOS-only; no UIKit code path exists. `TabPaneViewController`
  cannot be instantiated from a storyboard or XIB - `init?(coder:)` returns
  `nil` (formerly the normative requirement
  `view-controller-does-not-support-storyboard-instantiation`) - and every
  property and method that reads or mutates the pane's displayed state is
  confined to a `@MainActor` declaration, enforced at compile time by
  Swift's isolation checking (formerly the normative requirement
  `component-is-main-actor-confined`; this is the source of the Concurrent
  Access edge case above). The close button's accessibility description is
  a plain `String` passed to `accessibilityDescription`; unlike SwiftUI's
  `Text`/`Label`, whose literal argument is a `LocalizedStringKey`, a plain
  `String` parameter is not itself a localization key, so this string is
  genuinely unlocalized (see Localization above). A UIKit port would replace
  `NSBezierPath`/`draw(_:)` with `UIBezierPath`/`CAShapeLayer`, and would
  drive the recession move through `UIView.animate` or an explicit
  `CABasicAnimation` on the constraint's owning view, since UIKit has no
  `NSAnimationContext`/`allowsImplicitAnimation` equivalent for constraint
  changes.
- **WinUI 3**: Build the card as a `UserControl` whose visual is a
  `Microsoft.UI.Xaml.Shapes.Path` with a hand-built `PathGeometry`/
  `PathFigure` running through the same three corner points the card's own
  corner calculation computes - a XAML `Border` always strokes all four
  sides and cannot leave the workspace-facing side open, so it cannot
  express this shape directly. Bind the path's `Fill`/`Stroke` brushes to
  "Front"/"Behind" resource keys switched through a `VisualStateManager`
  state group. Animate the recession/overhang move with a `Storyboard`
  containing a `DoubleAnimation` (`Duration="0:0:0.16"`, `EasingFunction` a
  `QuadraticEase` with `EasingMode="EaseOut"`, mirroring the ease-out timing
  curve) targeting a `TranslateTransform` or `Margin`, gated on whether the
  control is currently in the visual tree - an unloaded control should call
  `Storyboard.SkipToFill()` to jump rather than animate, mirroring the
  animates-when-attached check. Lay out the header in a `Grid` with the
  close `Button` placed via `Grid.Column`/`HorizontalAlignment` depending on
  edge, its `Width`/`Height` fixed at `14` (not `Padding`) to match the
  fixed hit area, and size each status glyph's `FontIcon` at `11`px to
  mirror the icon's point size. Bind `AutomationProperties.AutomationId` to
  `"tab-pane." + tabId` (and `.agent.`/`.session.`/`.directory.`/`.branch.`/
  `.summary.`/`.close.` per sub-control) through a converter, matching the
  accessibility-identifier scheme.

