
- **SwiftUI**: Compose a custom `DisclosureGroup`-like container instead of
  the built-in `DisclosureGroup` (which has no slot for a collapsed one-line
  summary or a corner badge): a `VStack` holding a header `HStack` (optional
  leading accessory, `Text(title)` with low layout priority, a `Spacer`
  bounded by a minimum width, optional trailing accessory, and a rotating
  chevron `Button`) styled with `.background(elevatedSurfaceColor)`, and a
  conditional body below styled with `.background(surfaceColor)`. Reproduce
  the fold-independent width floor with a `.frame(minWidth:)` computed from
  both the open and folded content via `GeometryReader`/`PreferenceKey`
  measurement, since SwiftUI's conditional `if` view does not keep a
  detached branch measurable the way `NSStackView.isHidden` does. Draw the
  corner badge with `.overlay(alignment: .topTrailing)` and a small offset
  matching `cornerPeakInset`.
- **Compose**: Build the header as a `Row` with a `Modifier.background`
  matching the elevated surface color, an `Icon`/`IconButton` rotating 0↔180°
  for the disclosure state (Material has no single "disclosure triangle"
  control), and `AnimatedVisibility`/conditional composition for the body.
  Reserve the fold-independent width by measuring both the open and folded
  content with `SubcomposeLayout` and taking the wider `IntrinsicSize`,
  since a collapsed `AnimatedVisibility` composable does not otherwise keep
  its content measurable. Place the status badge with a `Box` using
  `Modifier.align(Alignment.TopEnd)` and an offset of
  `-(badgeDiameter / 2 − cornerPeakInset)` on both axes, so the badge is
  centered on the corner's arc rather than its edge.
- **React/Web**: A `<div>` with `aria-expanded` on its disclosure `<button>`
  (not `<details>`/`<summary>`, which has no slot for a collapsed one-line
  summary shown in place of the body and cannot support toggling the body
  via a CSS class rather than removal from the DOM); the header renders
  with the elevated background and a rotating disclosure `<button>`, and
  the body toggles via a CSS class (e.g. `.collapsed`) rather than
  `display: none`. Reserve the width floor by measuring both the open and
  collapsed header/body with `ResizeObserver` while both are rendered with
  `visibility: hidden; position: absolute` rather than `display: none` —
  `display: none` removes an element from measurement the way AppKit's
  `isHidden` does not. Position the status badge with `position: absolute;
  top: <peak>px; right: <peak>px; transform: translate(50%, -50%)`.
- **AppKit / UIKit** (source platform): The component (`DisclosureCardView`)
  is declared `@MainActor` and is an `NSView` subclass conforming to
  `Themeable`; it fails to compile if constructed or mutated from off the
  main actor, and it is unavailable via `init?(coder:)` — attempting to
  construct it from a storyboard/nib (`init?(coder:)`, declared
  `@available(*, unavailable)`) traps with a fatal error rather than
  returning a usable instance. Source at
  `packages/apple/AgenticToolkit/macOS/UI/Cards/DisclosureCardView.swift`
  (this recipe's source), plus its directory-mates `PinnedEndsLine.swift`
  (the header row's pinned-ends layout), `NSStackView+FullWidth.swift`
  (`addFullWidthArrangedSubview`, used to make the body section's rows fill
  the stack's width), and `CardFoldMemory.swift` (the host-side persistence
  and rebuild helper most callers wire this view to). This is macOS-only —
  `NSView`/`NSButton`/`NSStackView`/`NSTextField`/`NSImageView`; there is no
  UIKit code path in source. A UIKit port would replace those with
  `UIView`/a custom disclosure `UIButton` (UIKit has no built-in disclosure-
  triangle bezel style)/`UIStackView`/`UILabel`/`UIImageView`, and can reuse
  the same fold-independent width-floor technique directly, since
  `UIStackView.isHidden` behaves like `NSStackView.isHidden`: it detaches a
  hidden arranged view from the stack's layout while the view itself
  remains measurable via `intrinsicContentSize` when asked directly.

  API and literal mappings: the disclosure control is an `NSButton` with
  `bezelStyle = .disclosure` and `buttonType = .onOff`; its two states are
  `.off` (closed/collapsed indicator) and `.on` (open/expanded indicator).
  The card sets `clipsToBounds = false` on itself so the status badge can
  render outside its frame, and adds the badge as a sibling subview after
  the card surface — a `CALayer` otherwise draws a layer's own border
  above all of that layer's sublayers, so the badge must live outside the
  surface's layer tree to paint above its border. `dims-whole-card-
  uniformly` sets the whole view's `alphaValue`, not a substitute color
  set. The title text's line-break mode is `.byTruncatingMiddle`; the
  summary line's is `.byClipping`. Title/trailing-row shrink priority is
  expressed as Auto Layout compression-resistance/content-hugging
  priorities: `.defaultLow` for the title and its row, `.required` for the
  trailing row and other elements that must not shrink; the width-floor
  constraint's own priority is `999` (just under `.required`). Every
  scaled inset (`padX`, `padMastheadX`, `padY`, `padTitleY`, `mastheadGap`)
  is computed as
  `ceil(constant × scaledSize / NSFont.systemFontSize)` —
  `NSFont.systemFontSize` is the literal source of this recipe's "base
  system font size" (`baseFontSize`). The status badge renders `status` via
  `NSImage.symbol(named: status.symbolName, accessibilityDescription:
  status.accessibilityLabel)` (AgenticToolkitCoreUI's never-nil SF Symbol
  lookup, which substitutes a blank 16×16 template image for an unknown
  name) at a `.semibold` symbol configuration, and the title status symbol
  the same way at a point size of `scaledSize`; a placeholder is drawn at
  `alphaValue == 0`, never `isHidden`, since an `NSStackView` gives a
  hidden arranged view no room. The status badge's and title status
  symbol's accessibility role is set to `.image`. The whole-point title
  width comes from `WholePointLabel`, AgenticToolkitCoreUI's `NSTextField`
  subclass (`CoreUI/WholePointLabel.swift`) that rounds its
  `intrinsicContentSize` width up with `ceil`.
  The card draws no shadow: it sets no `shadowColor`, `shadowRadius`, or
  `shadowOpacity` on any `CALayer`. The source performs no
  `NSAnimationContext`/`CATransaction`-driven animation. Theme application
  happens via a `ThemePaletteObserver` held for the view's lifetime.
  `applyTheme(_:)` is the source's own theme-application entry point,
  invoked once at construction and again on every theme change; it is also
  what recomputes the masthead width floor from `summary` regardless of
  the card's `isCollapsed` value at construction.

  The recipe's descriptive terms above map to these source private members:
  the card surface is `surface`; the titlebar strip is `titlebar`; the
  titlebar's bottom rule is `titlebarRule`; the title text is `titleField`
  (a `WholePointLabel`); the title status symbol is `titleStatusIcon`; the
  title row is `titleLine`; the trailing row is `trailingLine`; the
  disclosure control is `disclosure`; the content area is `content`; the
  body section is `body`; the subtitle text is `subtitleField`; the summary
  line is `summaryField`; the status badge is `statusIcon`; and the
  width-floor constraint is `contentWidthFloor`. `color(named:)`'s
  name→role map (`"red"` → `dangerColor`, `"blue"` → `accentColor`, and so
  on) is defined outside this source, in
  `packages/apple/AgenticDeveloperToolkit/SourcesUI/macOS/Theme/SemanticPalette+NSColor.swift`.

  Public API surface (beyond construction):
  ```swift
  public func addContent(_ view: NSView)
  public var contentSpacing: CGFloat { get set }
  public var isCollapsed: Bool { get }
  ```
- **WinUI 3** (the reason this recipe exists): WinUI 3's `Expander` control
  is the nearest built-in analog — it already pairs a `Header` with
  collapsible `Content` and a built-in chevron that flips on `IsExpanded` —
  but it has no slot for a collapsed-only summary row and no corner badge,
  and critically: setting `Visibility="Collapsed"` on `Expander.Content`
  (or on any element) makes WinUI's layout system return a zero
  `DesiredSize` from `Measure()`, unlike AppKit's `NSView.isHidden`, which
  detaches a view from the visible layout while still returning its real
  `fittingSize` on request. Porting `floors-width-to-wider-of-open-or-
  folded-content` faithfully therefore requires NOT using
  `Visibility="Collapsed"` for the hidden state; instead, keep the content
  `Opacity="0"` and non-hit-testable (`IsHitTestVisible="False"`) while
  folded, or maintain an off-tree clone that stays measured, and bind a
  `Grid.MinWidth` computed from `max(openContentDesiredWidth,
  foldedSummaryDesiredWidth) + leadingGutter + trailingGutter`. Build the
  masthead as a `Grid` (`Border Background="{ElevatedSurfaceBrush}"`) with
  columns `Auto,*,Auto,Auto` (leading accessory, title `TextBlock` with
  `TextTrimming="CharacterEllipsis"` — WinUI has no built-in "truncate
  middle" trimming, so port `truncates-title-in-middle` as a custom
  `IValueConverter`/behavior if fidelity to that exact truncation point
  matters — trailing accessory, then a `ToggleButton` restyled to a
  rotating chevron glyph for the disclosure control since WinUI has no
  dedicated disclosure-triangle bezel). Draw the corner badge as a
  `FontIcon`/`SymbolIcon` inside a `Grid` cell placed with `Margin` set to
  `-(badgeDiameter / 2 − cornerPeakInset)` on the top and right edges (which
  centers the badge on the corner's arc rather than its edge) and
  `HorizontalAlignment / VerticalAlignment="Right"/"Top"`, with
  `Canvas.ZIndex` (or simple
  z-order in the `Grid`'s children) set above the `Border` that draws the
  card's own `BorderBrush`/`BorderThickness`, matching
  `draws-badge-above-surface-border`.
- **UI-thread confinement**: `confines-to-ui-thread` — the type is declared `@MainActor` and is an `NSView` subclass, so construction or mutation from off the main actor fails to compile.

