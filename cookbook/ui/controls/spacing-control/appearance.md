
- **Corner radius**: None. The outer frame and every pane are drawn as plain
  rectangles; no rounded corner appears anywhere in the implementation.
- **Padding**: Not a single vertical × horizontal pair — the whole control
  *is* a spacing editor, and its own outer padding is the fixed chrome
  reserved around the diagram for what hangs off it: arrow length (`18pt`)
  + arrow gap (`2pt`) + one field group's width/height (`40 + 2 + 13 =
  55pt` wide, `21pt` tall), i.e. `75×41pt` on each side of the diagram.
  Within that, an arrow's box sits `9pt` (half an arrow length) from the
  line it moves, and a divider's two arrow pairs stand `8pt` (half an arrow
  breadth plus half an arrow gap) either side of the divider's own centre
  line.
- **Font**: Number fields use the theme's code text style; the Reset
  control uses the theme's body text style. Neither font size is a literal
  in this file — both are theme tokens resolved by the shared theme model,
  out of this file's scope, and both repaint on a theme change.
- **Background**: The outer frame is filled with the theme's project-pane
  backdrop color; each pane (one for `frame`, four for `paneDividers`) is
  filled with the theme's window-background color. Both are theme tokens,
  not literal colors.
- **Foreground/Text**: Number field text uses the theme's primary-text
  color. Arrow glyphs are tinted with the theme's accent color. Neither is
  a literal color.
- **Border**: The outer frame is stroked `1pt` with the theme's border
  color; each pane is stroked `1pt` with the theme's project-pane outline
  color. Both are theme tokens, not literal colors. Both strokes are inset
  `0.5pt` on each side so a `1pt` stroke draws crisply at 1x display scale.
- **Shadow**: None. No shadow appears anywhere in the implementation.
- **Min/Max size**: Fixed natural size `420×250pt`; minimum size is the
  larger of two floors — three field groups across/down (`55×21pt` each,
  plus chrome), or the diagram's own floor for drawing the full range (tied
  to the maximum displayed inset of `40pt` per side, plus chrome). The
  diagram expands to fill the available area above the minimum; no maximum
  is enforced, since the diagram's drawn rectangle is measured from the
  available area on every layout pass.

