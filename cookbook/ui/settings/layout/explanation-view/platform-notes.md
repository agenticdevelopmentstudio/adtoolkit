
- **SwiftUI**: Compose a `Text(text)` with `.font(.caption)` and
  `.foregroundStyle(.secondary)` for the caption/secondary-text role
  pairing, and `.fixedSize(horizontal: false, vertical: true)` so the view
  wraps across lines and grows vertically rather than truncating — SwiftUI's
  analog of `wraps-across-lines` and `resists-vertical-compression`. Place
  it directly in the parent's layout with no fixed frame so it shrinks and
  wraps to the width it's given, mirroring
  `compresses-and-hugs-loosely-horizontally`.
- **Compose**: Use a `Text(text, style = MaterialTheme.typography.bodySmall,
  color = MaterialTheme.colorScheme.onSurfaceVariant)` — `bodySmall` is
  Material's regular-weight small body style, the closer fit for a wrapping
  paragraph than the medium-weight `labelSmall` style, which pairs a
  secondary-text color role with a caption-equivalent size — inside a layout
  slot with no fixed width, letting it wrap naturally; Compose `Text` wraps
  across lines and grows its own height by default, mirroring
  `wraps-across-lines` and `resists-vertical-compression` without extra
  configuration.
- **React/Web**: A `<p>`/`<span>` with `white-space: normal;
  overflow-wrap: break-word` (mirroring word-wrapping with no maximum line
  count) styled from the equivalent caption/secondary-text CSS custom
  properties, with `width: 100%` if it needs to fill its container
  edge-to-edge like `fills-view-edge-to-edge`, and no `max-height`/
  `-webkit-line-clamp` so it grows to fit like `resists-vertical-compression`.
- **AppKit / UIKit** (source platform): Source at
  `packages/apple/AgenticToolkit/macOS/SystemIntegration/ComposableSettingsWindow/Views/ExplanationView.swift`
  (this recipe's source): a macOS-only (`import AppKit`) `NSView` subclass,
  `@MainActor`-isolated, conforming to `SettingsViewProtocol` (an empty
  marker protocol every `ComposableSettings` row view conforms to, with no
  requirements of its own), inside the `ComposableSettings` namespace,
  wrapping one label built through the shared value-label factory
  (`ComposableSettings.makeValueLabel`, styled with the theme's
  `.secondaryText`/`.caption` roles per `styles-as-secondary-caption`) and
  reconfigured for multi-line wrapping and pinned edge-to-edge. `wraps-
  across-lines` is satisfied by setting `cell?.wraps = true`,
  `lineBreakMode = .byWordWrapping`, `cell?.usesSingleLineMode = false`, and
  `maximumNumberOfLines = 0`, overriding the shared `ThemedLabel` type's
  single-line, clipped default. `compresses-and-hugs-loosely-horizontally`
  is a horizontal content-compression-resistance priority of `.defaultLow`
  and a horizontal content-hugging priority of `.defaultLow`;
  `resists-vertical-compression` is a vertical content-compression-
  resistance priority of `.required`. The label is exposed as a public
  `label` property typed `NSTextField`. `ThemedLabel.init` sets
  `drawsBackground = false`, `isBordered = false`, and `isBezeled = false`
  on the label, matching the transparent, borderless appearance described
  above. The font-resolution chain is `ComposableSettings.makeValueLabel` →
  `ThemedLabel(textRole: .caption)` → `palette.font(.caption)`, which
  defaults to 11pt regular via `ThemeTypography.defaultStyle(.caption)`;
  `ExplanationView.createLabel`'s `monospacedDigits` parameter defaults to
  `false`. The source satisfies `requires-text-at-construction` by making
  `init(withText:)` the only usable initializer: both `override
  init(frame:)` and `required init?(coder:)` call `fatalError` instead of
  returning a usable instance — `init(frame:)`'s fatal-error message is a
  known source quirk (see Design Decisions) that a well-formed
  implementation should not reproduce. A UIKit port replaces
  `NSView`/`NSTextField` (`ThemedLabel`) with `UIView`/`UILabel`, sets
  `numberOfLines = 0` and `lineBreakMode = .byWordWrapping` (`UILabel`'s
  direct analogs of `maximumNumberOfLines`/`lineBreakMode`), and keeps the
  same horizontal-compressible/vertical-required priorities via
  `setContentCompressionResistancePriority(_:for:)`/
  `setContentHuggingPriority(_:for:)`. Unlike `NSView`, `UIView` does carry
  both a frame initializer and `init?(coder:)` — a UIKit port SHOULD mark
  both unavailable or fatal the same way to preserve
  `requires-text-at-construction`.
- **WinUI 3**: Build this as a `TextBlock`
  with `TextWrapping="WrapWholeWords"` (the analog of `lineBreakMode =
  .byWordWrapping` with `wraps = true`) and no `MaxLines` set (the analog of
  `maximumNumberOfLines = 0`, i.e. unlimited). Bind `TextBlock.Text` to the
  caller-supplied string (the analog of the `text` parameter and
  `renders-caller-text`), and set `HorizontalAlignment="Stretch"` with no
  fixed `Width` so the `TextBlock` shrinks and wraps to whatever column or
  panel width it's given, mirroring
  `compresses-and-hugs-loosely-horizontally`; leave height unconstrained
  (`Auto`-sized, the `Grid`/`StackPanel` default) so the control's height
  grows to fit its wrapped line count, mirroring
  `resists-vertical-compression`. Style `TextBlock.Foreground` and
  `TextBlock.FontSize`/`FontWeight` from the app's secondary-text/caption
  resource keys — WinUI 3 has no single built-in "secondary text" system
  brush the way the theme's `secondaryText` role derives one, so a Fluent
  app typically defines an equivalent style (e.g. a
  `CaptionTextBlockStyle`-derived resource with a muted foreground brush) in
  its resource dictionary rather than hardcoding a gray. There is no WinUI
  equivalent of constraint-based edge pinning beyond placing the
  `TextBlock` alone in its `Grid`/`StackPanel` cell with no `Margin`, which
  reproduces `fills-view-edge-to-edge` directly.

