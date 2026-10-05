
- **renders-card-as-rounded-bordered-surface**: Component MUST render its
  background as a rounded, bordered surface pinned to all four edges of the
  card, with a 10pt corner radius, a 1pt border, a background of the
  palette's `surfaceColor`, and a border color of the palette's
  `outlineColor`.
- **clips-titlebar-to-card-corners**: Component MUST clip the titlebar strip
  to the card's rounded corners, so the strip's own square top corners never
  draw past the card's curve.
- **renders-titlebar-as-elevated-strip**: Component MUST fill the titlebar
  strip with the palette's `elevatedSurfaceColor`, distinct from the card
  body's `surfaceColor`.
- **draws-titlebar-rule**: Component MUST draw a 1pt hairline along the
  titlebar's bottom edge, filled with the palette's `dividerColor` and
  spanning the titlebar's full leading-to-trailing width.
- **sizes-titlebar-to-header-plus-inset**: Component MUST size the titlebar
  strip's height to the header row's (title row plus trailing row) height
  plus the titlebar's own vertical inset (`padTitleY`, see Appearance) below
  it, never to the body section's height.
- **draws-badge-above-surface-border**: Component MUST add the status badge
  as a sibling view added after the card surface, so it paints above the
  surface's own border, which the surface's own rendering layer otherwise
  draws above all of that layer's nested content.
- **allows-badge-to-render-outside-frame**: Component MUST NOT clip its own
  contents to its bounds, so the status badge can be drawn partially outside
  the card's own frame.
- **displays-title-text**: Component MUST display the exact `title` string
  it was constructed with as the titlebar's title text.
- **truncates-title-in-middle**: Component MUST truncate the title text in
  the middle when it does not fit the available width.
- **yields-title-width-first**: Component MUST make the title text and its
  row the first element on the header row to shrink when space is tight, and
  MUST NOT let it grow to claim more width than its own text needs.
- **colors-title-by-accent-flag**: Component MUST color the title text with
  the palette's `accentColor` when `titleIsAccent == true`, and with
  `primaryTextColor` otherwise.
- **sets-title-font-semibold-body**: Component MUST set the title text's
  font to the palette's `.body` typography style with its weight overridden
  to semibold, resolved to a font at `scaledSize`.
- **places-title-accessory-leading**: When `titleAccessory` is non-nil,
  Component MUST place it immediately before the title text inside the
  title row, separated by the icon gap (`iconGap`, 6pt unscaled), and MUST
  hold the accessory at its natural width so only the title text — never
  the accessory — yields width.
- **places-title-status-after-title**: When `titleTrailingStatus` is
  non-nil, Component MUST draw it immediately after the title text inside
  the title row, separated by the icon gap, as a symbol icon named by
  `titleTrailingStatus.symbolName` drawn at a semibold weight at a size of
  `scaledSize` (the title's own size), and MUST hold it at its natural
  width, so only the title text — never the symbol — yields width.
  Component MUST NOT add anything after the title when
  `titleTrailingStatus` is `nil`.
- **exposes-title-status-like-badge**: For a `titleTrailingStatus` that is
  not a placeholder, Component MUST expose the symbol as its own
  accessibility element with an image accessibility role and accessibility
  label `titleTrailingStatus.accessibilityLabel`, and MUST set that same
  string as its tooltip.
- **reserves-placeholder-room-silently**: For a `titleTrailingStatus` made
  by `StatusSymbol.placeholder(sizedLike:)`, Component MUST keep exactly
  the room the named symbol would take in the title row — drawn fully
  transparent (opacity 0), never hidden, since a hidden element is given
  no room in the row — and MUST NOT expose it as an accessibility element
  or give it a tooltip.
- **asks-for-whole-point-title-width**: Component MUST report the title
  text's natural width rounded up to a whole point, so the width the
  card's floor measures for the title and the width the title is laid out
  at agree, and a title never truncates in a card given exactly its own
  fitting width.
- **places-titlebar-accessory-before-disclosure**: When `titlebarAccessory`
  is non-nil, Component MUST place it immediately before the disclosure
  control inside the trailing row, separated by the icon gap.
- **never-shrinks-trailing-line**: Component MUST hold the trailing row (the
  titlebar accessory, if any, plus the disclosure control) at its natural
  width and MUST NOT let it grow beyond that, so it never yields width to
  the title row.
- **maintains-minimum-header-gap**: Component MUST keep at least the
  masthead gap (`mastheadGap`, `ceil(24 × scaledSize / baseFontSize)`, see
  Appearance) between the title row's trailing edge and the trailing row's
  leading edge, and MUST vertically center-align the two rows on the header
  row.
- **renders-native-disclosure-control**: Component MUST render the fold
  control as the platform's native disclosure control, rather than a
  custom-drawn chevron.
- **sets-disclosure-initial-state**: Component MUST set the disclosure
  control's indicator to its closed position when constructed with
  `isCollapsed == true`, and to its open position when constructed with
  `isCollapsed == false`.
- **labels-disclosure-control**: Component MUST set the disclosure
  control's tooltip and accessibility label to `"Show details"` when
  constructed with `isCollapsed == true`, and to `"Hide details"` when
  constructed with `isCollapsed == false`.
- **forwards-toggle-state**: Component MUST invoke the toggle callback,
  passing `true` when the disclosure control's indicator becomes closed and
  `false` when it becomes open, whenever the user activates the disclosure
  control.
- **does-not-self-mutate-on-toggle**: Component MUST NOT change the content
  area's visibility, the body section's visibility, subtitle visibility, or
  the disclosure control's own tooltip/accessibility label as a direct
  result of activating the disclosure control — activating it only invokes
  the toggle callback. Folding is applied only by the host reconstructing
  the view with a new `isCollapsed` (see Design Decisions).
- **hides-content-when-collapsed**: Component MUST hide the content area for
  the lifetime of an instance constructed with `isCollapsed == true`, and
  show it for one constructed with `isCollapsed == false`.
- **builds-content-regardless-of-fold-state**: Component MUST add every
  view passed to the content-adding operation to the content area
  regardless of the card's current fold state, so a folded card's content
  remains measurable.
- **forces-subtitle-hidden-when-collapsed**: Component MUST hide the
  subtitle text when constructed with `isCollapsed == true`, even when a
  non-nil `subtitle` was supplied.
- **hides-subtitle-when-absent**: Component MUST hide the subtitle text when
  `subtitle == nil`.
- **detaches-empty-body**: Component MUST hide the entire body section
  (summary row, subtitle, and content) when constructed with
  `isCollapsed == true` and an empty `summary`, so the card renders as
  exactly its titlebar with no residual empty space beneath it.
- **matches-bottom-inset-to-empty-body**: Component MUST use the titlebar's
  own vertical inset (`padTitleY`), not the larger body inset (`padY`), as
  its own bottom inset when the body section is hidden, so a titlebar-only
  card's bottom edge sits `padTitleY` under the header, matching the
  header's own top inset.
- **shows-summary-only-when-collapsed-and-present**: Component MUST show
  the summary line only when constructed with `isCollapsed == true` AND a
  non-empty `summary`; it MUST be hidden in every other combination of
  those two inputs.
- **right-aligns-and-clips-summary-text**: Component MUST right-align the
  summary line's text, hold it at its natural width, and clip rather than
  truncate-with-ellipsis if the reserved width is ever exceeded.
- **formats-summary-parts**: Component MUST render each `SummaryPart` as
  `"<name>: <value>"`, with `name` in the palette's `.caption` style at
  `scaledSize × 0.85` colored `tertiaryTextColor`, and `value` in the
  palette's `.code` style at the same size colored by
  `part.color(palette)`, falling back to `secondaryTextColor` when that
  closure returns `nil`.
- **separates-summary-parts**: Component MUST insert a `"  |  "` separator,
  styled like a summary name (caption font, `tertiaryTextColor`), between
  each pair of adjacent `SummaryPart`s, and MUST NOT insert one before the
  first part or after the last.
- **hides-status-badge-when-absent**: Component MUST hide the status badge
  when `status == nil`.
- **renders-status-as-symbol-icon**: Component MUST render a non-nil
  `status` as a symbol icon named by `status.symbolName`, sized to the
  status badge's diameter for the current `scaledSize` (see
  `sizes-badge-diameter`) and drawn at a semibold weight, with
  `status.accessibilityLabel` as its accessibility description. An
  unresolvable symbol name yields a blank image rather than no image (see
  Edge Cases).
- **exposes-status-as-own-accessibility-element**: Component MUST expose
  the status badge as its own accessibility element with an image
  accessibility role and accessibility label `status.accessibilityLabel`,
  and MUST set that same string as its tooltip.
- **colors-status-badge**: Component MUST tint the status badge with
  `status.color(palette)` and the title status symbol with
  `titleTrailingStatus.color(palette)`, each asked of the live palette on
  every theme application and each falling back to `secondaryTextColor`
  whenever it returns `nil` (including when the `StatusSymbol` itself is
  `nil`, or was built with a `nil` `colorName`).
- **positions-badge-on-visible-corner**: Component MUST center the status
  badge, on both axes, `cornerPeakInset` (`cornerRadius − cornerRadius/√2`,
  ≈2.93pt at the fixed 10pt radius) inside the card's top-right corner —
  the point where the rounded corner's arc actually turns — not on the
  frame's literal square corner.
- **sizes-badge-diameter**: Component MUST size the status badge to
  `min(ceil(scaledSize × 1.3), padX × 1.5)` on each axis (see Appearance for
  `padX`).
- **dims-whole-card-uniformly**: Component MUST set the entire view's
  opacity to 0.55 when constructed with `isDimmed == true`, and to `1.0`
  otherwise, rather than substituting a separate set of dimmed colors.
- **scales-insets-with-text-size**: Component MUST scale
  `horizontalInset` (14), `mastheadInset` (7), `verticalInset` (12),
  `titlebarInset` (6), and the masthead gap (`mastheadGapAtSystemSize`, 24)
  linearly by `scaledSize ÷ baseFontSize` (the
  platform's own base system font size), rounding each result up, rather
  than using fixed point values.
- **floors-width-to-wider-of-open-or-folded-content**: Component MUST
  constrain its own width to be greater than or equal to the wider of (a)
  the content area's fitting width and (b) the masthead's folded-state
  width (the title-row-plus-trailing-row line, or the summary line,
  whichever is wider) — plus the masthead's leading gutter (`padMastheadX`)
  and trailing gutter (`padX`) — regardless of whether the card is
  currently open or folded, and whether or not it has a `summary`: a card
  with no summary still asks for the room to write its title whole.
- **keeps-width-floor-just-under-required**: Component MUST set the
  width-floor constraint's priority just under the layout system's
  required priority (specifically 999), so a container too narrow for the
  content scrolls rather than making the layout unsatisfiable.
- **remeasures-width-floor-on-layout**: Component MUST recompute its width
  floor on every layout pass, but MUST only apply the newly computed
  constant when it differs from the current one by more than 0.5pt.
- **applies-theme-immediately-and-on-change**: Component MUST apply the
  current theme once at construction and again on every subsequent theme
  change.
- **exposes-content-spacing**: Component MUST expose a `contentSpacing`
  property that reads and writes the content area's spacing, and MUST
  re-measure the width floor whenever it is set.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

