
- **SwiftUI**: Compose a `VStack(alignment: .leading, spacing: 0)` with a
  fixed `Text("Help").font(.headline)` (or a themed heading style) as the
  first child, and a `ScrollView { LazyVStack(alignment: .leading) {
  ForEach(topics) { topic in ... } } }` below it — the `VStack`'s own
  layout keeps the heading outside the `ScrollView`'s scroll content the
  same way `titleLabel` sits outside `PanelScrollView` here. Render each
  topic as a card-styled `GroupBox` or custom container plus a wrapping
  `Text` for the body, mirroring `GroupView` + `ExplanationView`. Show the
  fixed "No Help Yet" card when the topics array is empty, and drive the
  whole scroll content from a single `@State`/bound `HelpContent?` so
  reassigning it fully replaces the `ForEach` content the way
  `setHelp(_:)` does.
- **Compose**: Use a `Column { Text("Help", style =
  MaterialTheme.typography.titleMedium); Column(Modifier.verticalScroll(...))
  { topics.forEach { ... } } }` (or `LazyColumn` for long lists) — the
  outer `Column`'s heading stays fixed above the scrollable inner content
  the same way the AppKit heading sits above `PanelScrollView`. Render each
  topic as an `ElevatedCard` containing a title `Text` and a wrapping body
  `Text`, Compose's analog of `GroupView`/`ExplanationView`; recomposing
  with a new topics list naturally replaces the scrolled content the way
  `setHelp(_:)` rebuilds the panel.
- **React/Web**: A flex column with a non-scrolling `<h2>Help</h2>` header
  and a sibling `<div style="overflow-y: auto; flex: 1">` beneath it
  holding one card component per topic (a heading plus wrapping prose),
  re-rendered from whatever list state backs `content`; render a single
  "No Help Yet" card when that list is empty, and reset
  `scrollTop = 0` on the scrollable container whenever the topic list
  changes, mirroring **scroll-reset**.
- **AppKit / UIKit** (source platform): Source at
  `packages/apple/AgenticToolkit/macOS/UI/Help/HelpContentView.swift` (this
  recipe's source): a macOS-only (`import AppKit`) `NSView` subclass,
  `@MainActor`, composing one `NSTextField` heading with a
  `ComposableSettings.PanelScrollView` hosting a `ComposableSettings.PanelView`
  built from `GroupView`/`ExplanationView` rows. The class fails with a
  fatal error if constructed via `init(coder:)`, marked
  `@available(*, unavailable)` (`coder-init-unavailable`). It declares its
  own designated initializer, `public init()`, and overrides none of
  `NSView`'s designated initializers, so under Swift's initializer
  inheritance rules it inherits neither `init(frame:)` nor `init(coder:)` —
  `HelpContentView(frame:)` does not compile, and (unlike sibling
  `ComposableSettings` row views such as `ExplanationView` or
  `DisclosureCardView`) it needs no fatal-error override to block that path,
  since `init()` is the only initializer Swift synthesizes access to. It is
  a plain `NSView` with `wantsLayer = true` but no `cornerRadius` set on its
  own layer; the topic card's own rounding is
  `SettingsLayout.default[.cardCornerRadius]` (10pt), and the heading/scroll
  inset is `SettingsLayout.default[.panelInset]` (20pt). The heading font is
  `palette.font(.heading)`, which defaults to
  `ThemeTypography.defaultStyle(.heading)` (15pt semibold) and scales with
  `sizeScale`. `PanelScrollView` draws no background of its own
  (`drawsBackground = false`); `PanelView` separately paints its own layer
  with `windowBackgroundColor` via its own `ThemePaletteObserver` instance —
  this view resolves and reapplies `SemanticPalette` the same way, on
  `ThemePaletteObserver`'s theme-change notification. The heading label is
  `NSTextField(labelWithString:)`, which AppKit exposes to assistive
  technology as static text by default; `titleLabel` is never given
  `setAccessibilityRole(.staticText)` with a heading subrole
  (`HelpContentView.swift`, `:31-32`). Content replacement calls
  `PanelScrollView.setContent(_:)`, which removes the document view's prior
  subviews and re-pins the new one from the document's top edge (producing
  `scroll-reset` as a side effect), and posts no
  `NSAccessibility.post(element:notification:)` call anywhere in
  `HelpContentView.swift`, `PanelScrollView.swift`, or `PanelView.swift`.
  `HelpContent` (`HelpContent.swift`) is `Sendable`/`Equatable` and holds an
  ordered array of `Topic`, each a `title`/`body` string pair.
  `NSTextField(labelWithString:)` sets `stringValue` from a Swift string
  literal directly; unlike a SwiftUI `Text` literal (a `LocalizedStringKey`),
  an AppKit `stringValue` set this way is not itself localizable, and no
  `NSLocalizedString` lookup or string-catalog reference appears anywhere in
  source. No `NSAnimationContext`/`CATransaction` call appears in source
  either. A UIKit port replaces `NSTextField` with a `UILabel`,
  `PanelScrollView`/`PanelView` with a `UIScrollView` hosting a
  `UIStackView` of card views, and `ThemePaletteObserver`'s AppKit-side
  theme-change notification with UIKit's own trait-collection/theme-change
  hook. The constraint equations behind **fixed-help-heading** and
  **independently-scrolling-content**:
  `titleLabel.topAnchor == self.topAnchor + inset`,
  `titleLabel.leadingAnchor == self.leadingAnchor + inset`,
  `titleLabel.trailingAnchor <= self.trailingAnchor - inset`,
  `scrollView.topAnchor == titleLabel.bottomAnchor`, and
  `scrollView`'s leading/trailing/bottom anchors each equal to `self`'s
  with no constant, where `inset` is
  `ComposableSettings.SettingsLayout.default[.panelInset]` (20pt). Public API
  surface:
  ```swift
  public init()
  public func setHelp(_ content: HelpContent?)
  ```
- **WinUI 3** (the reason this recipe exists): Build this as a two-row
  `Grid`: row 0, `Auto` height, holds a `TextBlock Text="Help"` styled with
  `SubtitleTextBlockStyle` (the Fluent 2 analog of the 15pt semibold
  heading font), inset from the grid's edges by a 20px `Margin` to match
  `panelInset`; row 1, `*` height, holds a `ScrollViewer` with
  `VerticalScrollBarVisibility="Auto"` containing an `ItemsRepeater` (or
  `ItemsControl`) bound to an `ObservableCollection<Topic>`. Template each
  topic as a `Border` styled with `CardBackgroundFillColorDefaultBrush` and
  `CornerRadius="10"` (matching `cardCornerRadius`), containing a
  `TextBlock` for the title (`BodyStrongTextBlockStyle`) and a wrapping
  `TextBlock` for the body (`BodyTextBlockStyle`,
  `TextWrapping="WrapWholeWords"`) — WinUI 3's analogs of `GroupView`'s
  header and `ExplanationView`. Swap the bound collection's contents (or
  reset it to a single "No Help Yet" item) on every call that plays the
  role of `setHelp(_:)`, and call
  `scrollViewer.ChangeView(null, 0, null, true)` immediately after, to
  reproduce **scroll-reset** — `ItemsRepeater`
  does not reset scroll position on its own the way `PanelScrollView`'s
  `setContent(_:)` does. Bind `Border.Background` (the topic card) to
  `{ThemeResource LayerFillColorDefaultBrush}` and `TextBlock.Foreground`
  to `{ThemeResource TextFillColorPrimaryBrush}`, but bind the outer
  `Grid`'s own `Background` to `{ThemeResource
  SolidBackgroundFillColorBaseBrush}` — the window's own ground, not a
  distinct layer color — to reproduce **window-background**: the cards
  read as elevated only because the grid behind them matches the window,
  the same way `windowBackgroundColor` does here. Bind all three through
  `{ThemeResource}` rather than a fixed color, so `RequestedTheme`/
  light-dark changes repaint automatically the way `ThemePaletteObserver`
  repaints this view on every theme change.
- **UI-thread confinement**: `confines-to-ui-thread` — the type is declared `@MainActor` and is an `NSView` subclass, so construction or mutation from off the main actor fails to compile.

