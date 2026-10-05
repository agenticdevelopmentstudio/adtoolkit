
- **Empty `title`** (`""`): Documented limitation — `displays-title-text`
  requires the exact `title` string to be displayed, and the source performs
  no empty-string check: the title text renders an empty string and the
  header row lays out with a zero-width title.
- **Very long `title` with no accessories**: truncated in the middle rather
  than the tail or head (MUST, per `truncates-title-in-middle`); the
  required minimum header gap and the trailing line's required compression
  resistance keep the disclosure control fully visible regardless of title
  length (MUST, per `maintains-minimum-header-gap` and
  `never-shrinks-trailing-line`).
- **`summary` non-empty while `isCollapsed == false` at construction**: the
  summary row itself stays hidden (per `shows-summary-only-when-collapsed-
  and-present`), but the masthead width floor (see Appearance) is still
  computed from `summary` whenever the theme is applied, regardless of
  `isCollapsed`, so an initially-open card's width floor already reserves
  room for the summary line it would show if folded (MUST, per
  `floors-width-to-wider-of-open-or-folded-content`).
- **`summary` empty and `isCollapsed == true`**: the card renders as
  exactly its titlebar, with the body section fully detached and the
  bottom inset switched to `padTitleY` (MUST, per `detaches-empty-body`
  and `matches-bottom-inset-to-empty-body`).
- **A `StatusSymbol.symbolName` does not resolve to a valid symbol icon**:
  Documented limitation — `renders-status-as-symbol-icon` and
  `places-title-status-after-title` require a symbol icon, and the source
  performs no validation of `symbolName`: the symbol lookup substitutes a
  blank 16×16 image, so the badge (or the symbol after the title) keeps its
  frame, position, and accessibility label/tooltip, but no glyph paints. A
  placeholder sized like an unresolved name holds that blank image's 16pt
  of room.
- **Extreme `scaledSize` values** (very small, e.g. approaching 0, or very
  large, e.g. an accessibility "larger text" size well above the 13pt
  baseline): every inset and font scales linearly and is rounded up, with
  no minimum clamp — an extremely small `scaledSize` can drive insets
  toward 0pt. The status badge diameter is the one value with an explicit
  upper bound (`min(ceil(scaledSize × 1.3), padX × 1.5)`, with `padX`
  evaluated at that `scaledSize` — see Appearance); every other scaled
  constant is otherwise unbounded above (MUST, per
  `scales-insets-with-text-size` and `sizes-badge-diameter`).
- **Concurrent access**: Not applicable — this component is confined to a
  single thread of execution for its entire lifetime, so there is no
  concurrent-access surface for it to define behavior for. See Platform Notes for how that confinement is enforced.
- **Error states (dependency/network failure)**: Not applicable — the
  source performs no network call, database access, or file-system I/O of
  any kind.
- **Offline/disconnected state**: Not applicable — the component has no
  networking dependency of its own.
- **Boundary values**: `cornerRadius`, `borderWidth`, `horizontalInset`,
  `verticalInset`, `titlebarInset`, `mastheadInset`,
  `mastheadGapAtSystemSize`, `iconGap`, and `dimmedAlpha` are fixed
  literals, not caller-configurable ranges with a boundary to test (the gap
  itself scales with `scaledSize`, per `scales-insets-with-text-size`). `scaledSize` is the one
  caller-configurable numeric input; its boundary behavior is covered
  above under "Extreme `scaledSize` values."

