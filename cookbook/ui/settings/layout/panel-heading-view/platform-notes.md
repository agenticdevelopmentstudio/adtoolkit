
- **SwiftUI**: Compose a `VStack(alignment: .leading, spacing: 6)` with a
  `Text(title)` styled from the app's `.heading` theme token (the SwiftUI
  analog of `ThemeTypography.defaultStyle(.heading)`, not the built-in
  `.headline` text style, which is a different size/weight on this platform)
  for the title, and — only when `caption` is non-`nil` — a `Text(caption)
  .font(.caption).foregroundStyle(.secondary)
  .fixedSize(horizontal: false, vertical: true)` beneath it, mirroring
  `stacks-title-and-caption-vertically-leading-aligned` and
  `creates-caption-view-when-caption-given`/
  `omits-caption-view-when-caption-nil`. Give the caption `Text` no fixed
  frame beyond the parent's own width so it wraps to it, the SwiftUI analog
  of `matches-caption-width-to-stack`; leave the title unconstrained in width
  to match the source's clipped, single-line title.
- **Compose**: Use a `Column(verticalArrangement = Arrangement
  .spacedBy(6.dp), horizontalAlignment = Alignment.Start)` with a
  `Text(title, style = MaterialTheme.typography.titleMedium)` for the
  heading, and conditionally (`if (caption != null)`) a
  `Text(caption, style = MaterialTheme.typography.bodySmall, color =
  MaterialTheme.colorScheme.onSurfaceVariant)` that wraps within the
  column's own width — Compose `Text` wraps by default, mirroring the
  caption's wrapping behavior without extra configuration.
- **React/Web**: A `<hgroup>` or `<div>` containing a heading element (e.g.
  `<h3>`) styled from the primary-text/heading tokens, followed — only when
  `caption` is provided — by a `<p>` styled from the
  secondary-text/caption tokens with `white-space: normal; overflow-wrap:
  break-word` and `width: 100%` so it wraps to the container, mirroring
  `matches-caption-width-to-stack`; use `gap: 6px` (flex or grid column) for
  the title-to-caption spacing, matching `spaces-title-from-caption`.
- **AppKit / UIKit** (source platform): Source at
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/PanelHeadingView.swift`
  (this recipe's source): a macOS-only (`import AppKit`) `NSView` subclass,
  `@MainActor`, `final`, inside the `ComposableSettings` namespace,
  conforming to `SettingsViewProtocol` (a marker protocol with no
  requirements of its own that every settings-row view in this system
  adopts), composing one `ThemedLabel` (`titleLabel`, styled `role:
  .primaryText, textRole: .heading`) and, conditionally, one
  `ExplanationView` (`captionView`) inside an `NSStackView`.
  `confines-to-ui-thread` is enforced at compile time by the class's
  `@MainActor` declaration. `fills-bounds-with-zero-inset` is met by
  setting `translatesAutoresizingMaskIntoConstraints = false` on the view
  itself, the stack, and `titleLabel` (`captionView` opts itself in inside
  `ExplanationView`'s own initializer — this component does not set it a
  second time), then activating four `NSLayoutConstraint`s pinning the
  stack's top, leading, trailing, and bottom anchors to the matching
  anchors of the view itself, each with a zero constant.
  `requires-title-at-construction` is met by overriding `init(frame
  frameRect: NSRect)` to `fatalError("init(frame frameRect: NSRect)")`
  unconditionally, and `init?(coder: NSCoder)` to `fatalError("init(coder:)
  has not been implemented")`; the only supported construction path is
  `init(title:caption:)`, which requires `title`. There is no UIKit code
  path in source. A UIKit port would replace `NSStackView` with
  `UIStackView`, `ThemedLabel`(`NSTextField`) with a `UILabel` styled for
  the heading role, and the conditionally-constructed
  `ExplanationView`/`UILabel` pairing for the caption; it would have no
  `NSCoder`-vs-frame initializer split to fatal-error on the way the
  source does.
- **WinUI 3**: Build this as a vertical
  `StackPanel` with `Spacing="6"` (the analog of
  `SettingsLayout.default[.captionSpacing]` /
  `spaces-title-from-caption`) containing a `TextBlock` styled
  `Style="{StaticResource BodyStrongTextBlockStyle}"` (or a custom style
  matching the theme's `.heading` size/weight) bound to `title`, mirroring
  `styles-title-as-primary-heading`/`sets-title-text-from-caller`. Add a
  second `TextBlock` — constructed and added to the `StackPanel.Children`
  only when `caption` is non-null, not merely hidden via `Visibility`, to
  mirror `creates-caption-view-when-caption-given`/
  `omits-caption-view-when-caption-nil` and to keep the component's own
  caption-label accessor honest for a null caption — styled
  `Style="{StaticResource CaptionTextBlockStyle}"` with
  `TextWrapping="WrapWholeWords"` and `HorizontalAlignment="Stretch"` so it
  wraps to the `StackPanel`'s own width, mirroring
  `matches-caption-width-to-stack` (a `StackPanel`'s children stretch to its
  width by default when no narrower `Width` is set, unlike the title label,
  which should keep `TextWrapping="NoWrap"` and `TextTrimming="Clip"` to
  match the source's untouched, single-line default). There is no WinUI
  equivalent of the constraint-based edge pinning needed beyond placing the
  `StackPanel` alone in its parent cell with no `Margin`, reproducing
  `fills-bounds-with-zero-inset` directly.

