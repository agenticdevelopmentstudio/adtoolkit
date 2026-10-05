
- **SwiftUI**: Start from a small container view (or `ViewModifier`) wrapping
  a `Text`, applying `.padding(.horizontal, 6).padding(.vertical, 2)` and
  `.background(color, in: RoundedRectangle(cornerRadius: 5))` for the
  filled background — `.clipShape(RoundedRectangle(cornerRadius: 5))`
  alone only clips, it paints no fill — or `.overlay(RoundedRectangle(cornerRadius: 5).stroke(color,
  lineWidth: 1))` for outlined. SwiftUI has no built-in equivalent of
  `contrastingTextColor(on:)`, so port the same luminance formula as a small
  helper function, and reconcile the caption font with SwiftUI's Dynamic Type
  system rather than a raw `.caption` font size.
- **Compose**: Start from a `Box`/`Surface` with `shape =
  RoundedCornerShape(5.dp)` and a centered `Text` inset by
  `Modifier.padding(horizontal = 6.dp, vertical = 2.dp)`. Material 3's
  `AssistChip`/`SuggestionChip` are the nearest built-in analogs but carry
  interaction states (ripple, enabled/disabled) that this component does
  not have, so a plain `Box` + `Text` composition matches its
  non-interactive nature more faithfully. Reimplement the luminance-based
  text-color choice, since Compose's `contentColorFor` derives from the
  Material color scheme rather than computing per-arbitrary-color contrast.
- **React/Web**: Use an inline-block `<span>` with `border-radius: 5px`,
  `padding: 2px 6px`, background/border/color driven by the equivalent style
  prop, and a `getContrastingTextColor` helper reimplementing the same
  0.299/0.587/0.114 luminance weights and 0.6 threshold. The sibling web
  Badge recipe (`adtoolkit://cookbook/ui/controls/badge`) already implements
  this on the web; reuse its formula so filled-style contrast decisions agree
  across platforms rather than re-deriving a possibly different threshold.
- **AppKit / UIKit** (source platform): Source at
  `packages/apple/AgenticToolkit/macOS/UI/Badge/Badge.swift` (this recipe's
  source): a macOS-only, `@MainActor`-isolated `NSView` subclass owning an
  `NSTextField(labelWithString:)`, styled via `CALayer`
  (`layer?.cornerRadius = 5`, `backgroundColor`, `borderWidth`,
  `borderColor`) and `NSColor`. The class and its public API are declared
  `@MainActor`, so construction or mutation from off the main actor fails
  to compile — this is `confines-to-ui-thread`, a static,
  compile-time check rather than a vector observed by running the program;
  a port on a platform without an equivalent compile-time enforcement
  should verify this as a build-verification note rather than a runtime
  test. It fails with a fatal error if constructed via `init?(coder:)`
  (`Badge(coder:)`, e.g. via nib/storyboard unarchiving) — this is
  `rejects-storyboard-instantiation`. The label centers its text via
  `label.alignment = .center`; the color-to-sRGB check behind
  `falls-back-to-white-on-unconvertible-color` is
  `NSColor.usingColorSpace(.sRGB)` returning `nil`; the caption font stays
  in sync via an `observeTheme` extension. The component never overrides
  responder-chain behavior, so `NSView`'s own default
  (`acceptsFirstResponder == false`) applies unmodified. Its
  `NSTextField(labelWithString:)` label reflects `stringValue` changes
  through AppKit's own accessibility support with no custom code here; it
  reads no system contrast setting such as
  `NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast`, and
  style changes are plain synchronous property assignment with no
  `CATransaction`. Test vectors that reference a system-provided color use
  AppKit's dynamic system colors (`.systemGreen`, `.systemRed`,
  `.systemGray`, `.systemBlue`) under a fixed `NSAppearance` (e.g. `.aqua`),
  since these resolve to different `CGColor` values under light vs. dark
  appearance. A UIKit port replaces `NSView`/`NSTextField`/`NSColor` with
  `UIView`/`UILabel`/`UIColor`, uses `layer.cornerRadius` the same way, and
  must re-derive the `.caption`-equivalent font from whatever theme
  abstraction the iOS app uses, since this source's `observeTheme`
  extension is macOS-only (`AgenticToolkitCoreMacOS`). The
  Interface-Builder-rejecting `init?(coder:)` pattern carries over
  unchanged. Public API surface:
  ```swift
  public enum Style: Sendable {
      case filled
      case outlined
  }

  public init(text: String, color: NSColor, style: Style = .filled)
  public func update(text: String, color: NSColor, style: Style = .filled)
  ```
- **WinUI 3**: Start from a `Border` wrapping a `TextBlock`, since WinUI 3 has
  no single control offering both filled and outlined chip states for
  arbitrary text (`InfoBadge` is numeric/dot-only and cannot host a text label
  like `"dev"` or `"stopped"`). Set `Border.CornerRadius="5"` to match the 5px
  radius and `Border.Padding="6,2,6,2"` to match the leading/trailing-6,
  top/bottom-2 padding. Bind `Border.Background`, `Border.BorderBrush`,
  `Border.BorderThickness`, and the inner `TextBlock.Foreground` to the same
  two branches the style switch resolves: filled sets `Background=color`,
  `BorderThickness=0`, `TextBlock.Foreground` to the computed black/white;
  outlined sets `Background=Transparent`, `BorderThickness=1`,
  `BorderBrush=color`, `TextBlock.Foreground=color`. WinUI 3 has no built-in
  API for computing contrasting text color from an arbitrary `Color`, so port
  `contrastingTextColor(on:)` as a small static helper using the same
  0.299/0.587/0.114 weights and 0.6 threshold. Give the `Border`
  `HorizontalAlignment="Left"` (or wrap it in a `StackPanel`) so it hugs its
  content instead of stretching, matching the component's required
  horizontal content-hugging (`sizes-to-fit-content`).

