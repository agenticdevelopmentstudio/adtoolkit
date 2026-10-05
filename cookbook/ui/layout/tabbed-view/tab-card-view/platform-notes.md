
- **SwiftUI**: Model the open-sided outline as a custom `Shape` (a
  `path(in:)` implementation tracing the same four points
  `TabCardBackgroundView.corners(of:)` does, per edge, and never closing back
  across the workspace-facing side), composed as a `.background`/`.overlay`
  pair (fill, then stroke) behind a `VStack` mirroring the content column's
  order (header `HStack`, then the four remaining labels, then a `Spacer()`
  in place of the trailing spacer). Drive front/recession/overhang from a
  passed-in `depth: Int`, and wrap the shape's frame/offset change in
  `.animation(.easeOut(duration: 0.16), value: depth)` — gated behind
  `@Environment(\.accessibilityReduceMotion)` per the Reduce Motion gap noted
  above. Use `.lineLimit(1)` with `.truncationMode(.middle)`/`.head`/`.tail`
  to match the per-label truncation modes.
- **Compose**: Draw the same open-sided outline with a `Canvas`/`Path` in a
  `Box`, sized by a `Modifier.widthIn(min = 240.dp, max = 340.dp)` /
  `heightIn(min = 136.dp)`. Represent front/behind with an `animateDpAsState`
  (or `animateFloatAsState`) driving inset/offset over `160.milliseconds`
  with an `EaseOut` easing curve, checked against the system animator
  duration scale (`Settings.Global.ANIMATOR_DURATION_SCALE`, read via
  `ContentResolver` — a scale of zero means Reduce Motion is on;
  `LocalAccessibilityManager` does not expose this setting) before animating.
  Lay out the header as a `Row` with a `Spacer(Modifier.weight(1f))`
  in place of the gap, and the remaining lines in a `Column`, each using
  `TextOverflow.StartEllipsis`, `TextOverflow.MiddleEllipsis`, or
  `TextOverflow.Ellipsis` to match the per-label head/middle/tail truncation
  mode (`Modifier.basicMarquee()` scrolls text rather than truncating it, so
  it does not apply here).
- **React/Web**: Build the card as a `<div>` whose background fills the
  full rect but whose border is set on only three sides (the CSS
  longhands `border-top`/`border-left`/`border-right`, omitting the
  workspace-facing side) — or, for the exact open-path stroke, an inline SVG
  `<path>` built from the same four points. Transition `margin`/`transform`
  over `0.16s ease-out` for the depth change, gated behind a
  `prefers-reduced-motion: reduce` media query per the Reduce Motion gap
  above. Use CSS `text-overflow: ellipsis` for tail truncation, `direction:
  rtl` on an inner span for head truncation (the directory-label case), and
  a `<button aria-label="Close">` for the close control.
- **AppKit/UIKit** (source platform): Implemented in
  `packages/apple/AgenticToolkit/macOS/UI/ViewControllers/MultiTabbedViewController/TabPane/TabPaneView.swift`
  (`TabPaneView`, plus the file-private `InsetBox`, `CardSides`, and
  `TabCardBackgroundView` types), hosted by `TabPaneViewController.swift` in
  the same directory. This is a macOS-only, AppKit `NSView` component with no
  UIKit code path in source. The type is `final` and confines its mutable
  state via a `@MainActor` declaration — construction and mutation are
  restricted to the main actor, enforced at compile time by Swift's isolation
  checking (this is the source of the Concurrent Access edge case above).
  `init?(coder:)` is `@available(*, unavailable)` and returns `nil`, so the
  type cannot be constructed from a storyboard or XIB (formerly the
  normative requirement `init-from-coder-unavailable`); `self`, the
  background box, and the content stack all set `wantsLayer = true` during
  setup, so all three are layer-backed for coloring and animation (formerly
  the normative requirement `wants-layer-on-self-and-boxes`). Icons are SF
  Symbols: the close control uses `xmark.circle.fill` with `imagePosition =
  .imageOnly`, no bezel (`isBordered = false`, `bezelStyle = .inline`); the
  one built-in status symbol, `.idle`, uses `moon.zzz`; a status icon whose
  name fails to resolve falls back to an empty `NSImage()`. Depth-change
  animation uses a `CAMediaTimingFunction(name: .easeOut)` and reports its
  progress via the running `CALayer` animation keys on the background and
  content boxes (this is the source of the `running-move-animations-accessor`
  requirement above). A UIKit port has no first-class analog to an
  `NSBezierPath`-drawn, three-sided open card that overhangs a sibling view
  by a point; it would use a plain `UIView` with a `CAShapeLayer` (a
  `UIBezierPath` built the same four-point, open-path way, `fillColor` and
  `strokeColor` set from the palette) and `UIView.animate(withDuration:)` (or
  `UIViewPropertyAnimator` with an ease-out curve) for the depth transition,
  checking `UIAccessibility.isReduceMotionEnabled` first.
- **WinUI 3** (the reason this recipe exists): There is no single WinUI 3
  control for an open-sided, overhanging tab card, so build it as a
  `UserControl`/`Grid` whose background is a plain `Rectangle`/`Border`
  `Fill` (WinUI's `Border` strokes all four sides at once, so reproduce the
  open workspace-facing side with a `Path`/`Geometry` built from the same
  four corner points `corners(of:)` computes, or by drawing three separate
  `Line`/`Rectangle` strokes and simply omitting the fourth) sized between
  `MinWidth="240" MaxWidth="340" MinHeight="136"`. Drive the front/behind
  recession and the front card's one-pixel overhang with a `Margin` bound to
  a view-model property, animated by a `Storyboard`
  `DoubleAnimation`/`ThicknessAnimation` (`Duration="0:0:0.16"`, an
  `EasingFunction` matching ease-out, e.g. `CubicEase EasingMode="EaseOut"`),
  skipped in favor of an immediate `Margin` set when
  `Windows.UI.ViewManagement.UISettings.AnimationsEnabled` (or the app's own
  Reduce Motion setting) is off — mirroring the Reduce Motion gap noted
  above, which this port should not repeat. Swap `Background`/`Foreground`
  `SolidColorBrush`es between the front and behind palettes with a
  `VisualStateManager` `FrontCard`/`BehindCard` state group, the way the
  appearance-update logic swaps palette roles. Lay out the header as a
  `Grid` with `Auto,Auto,*,Auto` columns (agent label, status stack, gap,
  close button) — a horizontal `StackPanel` cannot host a star-sized column,
  so the third column's `*` sizing takes the place of the gap, absorbing the
  header's extra width — followed by a close `Button` in the fourth column,
  styled borderless (`Style="{StaticResource TransparentButtonStyle}"` or
  equivalent), sized `14x14`, using the Segoe Fluent Icons `&#xE711;`
  ("Cancel") glyph, with `AutomationProperties.Name="Close"`. Represent the
  status symbols as a horizontal `ItemsRepeater`/`StackPanel` of `14x14`
  `FontIcon`s, each with its own `AutomationProperties.Name` bound to the
  caller-supplied label. Bind `MinWidth`/`MinHeight` growth to the hosted
  content's measured `DesiredSize` plus the recession slack, mirroring the
  content size calculation.

