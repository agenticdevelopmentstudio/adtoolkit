
- **Corner radius**: 10pt, fixed (`cornerRadius`); unaffected by
  `scaledSize`.
- **Padding**: `padX` = `ceil(14 × scaledSize / baseFontSize)`, the
  card's trailing gutter — from the card edge to body/content rows and to
  the summary/subtitle's trailing edge; `padMastheadX` =
  `ceil(7 × scaledSize / baseFontSize)`, the masthead's own
  leading gutter — from the card edge to the masthead line's leading edge;
  `padY` = `ceil(12 × scaledSize / baseFontSize)` as the card's own
  bottom inset when the body section is present; `padTitleY` =
  `ceil(6 × scaledSize / baseFontSize)` as the titlebar's own
  top/bottom inset, and as the card's bottom inset when the body section is
  hidden; `iconGap` = 6pt fixed between an accessory or the title status
  symbol and the text/control beside it; `mastheadGap` =
  `ceil(24 × scaledSize / baseFontSize)` minimum between the title row and
  the trailing row. The masthead's own width floor (below) reserves
  `padMastheadX` on its leading side and `padX` on its trailing side — the
  same two gutters the card itself is pinned at.
- **Corner peak inset**: `cornerPeakInset` = `cornerRadius − cornerRadius/√2`
  (≈2.93pt at the fixed 10pt `cornerRadius`) — the distance in from the
  frame's literal corner, on both axes, to the point where the rounded
  corner's arc actually turns — what the status badge is centered on.
- **Badge diameter**: `min(ceil(scaledSize × 1.3), padX × 1.5)` — the status
  badge's width and height at a given `scaledSize`.
- **Title status symbol**: drawn at a size of `scaledSize`, semibold
  weight — the title's own size, since it reads as part of the name — at
  its natural size, with no fixed frame of its own.
- **Masthead width floor**: for every card, the wider of (a) the title
  row's fitting width (leading accessory, whole-point title width, and
  title status symbol or placeholder included) plus `mastheadGap` plus the
  trailing row's fitting width, and (b) the summary line's rendered text
  width when `summary` is non-empty, `0` when it is empty. Feeds `floors-width-to-wider-of-open-or-folded-
  content`.
- **Font**: title — palette `.body` style, weight forced to semibold, at
  `scaledSize`; subtitle and summary names — palette `.caption` style at
  `scaledSize × 0.85`; summary values — palette `.code` style at
  `scaledSize × 0.85`.
- **Background**: card body — palette `surfaceColor`; titlebar strip —
  palette `elevatedSurfaceColor`.
- **Foreground/Text**: title — `accentColor` when `titleIsAccent`,
  otherwise `primaryTextColor`; subtitle, summary names, and the summary
  separator — `tertiaryTextColor`; summary values — each `SummaryPart`'s
  own resolved color, falling back to `secondaryTextColor`; disclosure
  control tint — `secondaryTextColor`; status badge tint —
  `status.color(palette)`, and title status symbol tint —
  `titleTrailingStatus.color(palette)`, each falling back to
  `secondaryTextColor`.
- **Border**: card surface — 1pt, palette `outlineColor`; titlebar rule —
  1pt, palette `dividerColor` (a filled strip along the titlebar's bottom
  edge, not a stroked border).
- **Shadow**: none — no shadow effect (color, radius, or opacity) is
  applied to any layer of the card.
- **Min/Max size**: none declared as fixed constants. The card's only size
  constraint is the dynamic width-floor constraint (priority 999) described
  above; no explicit minimum or maximum height, and no upper bound on
  width.

