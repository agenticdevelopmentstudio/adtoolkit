
- **Corner radius**: `4pt` on a tab button's background pill. The bar and
  hosted-item wrapper set no corner radius of their own.
- **Padding**: Inside a tab button: `10pt` from the background's leading
  edge to the title label; `4pt` between the title label and the
  background's top/bottom; `6pt` between the title label and the close
  button; `6pt` from the close button to the background's trailing edge;
  the background itself is inset `2pt` from the button's own top and
  bottom. Inside the bar: `6pt` between an item and the bar's outer
  (window) side only — the workspace side is flush; `8pt` at each end of
  the bar along its length, overridable per instance via the start inset;
  `4pt` between items on a horizontal bar, or `-16pt` (a negative gap) on a
  vertical bar.
- **Font**: The `caption` text role for a tab button's title label —
  resolved size and weight come from the active theme's typography, not a
  fixed point size; the role does not change with selection, only the
  label's color role does (see Foreground/Text).
- **Background**: The bar fills with the `windowBackground` palette role. A
  tab button's background fills with the `selection` role when highlighted
  and is transparent otherwise. The hosted-item wrapper draws no background
  of its own.
- **Foreground/Text**: A tab button's title color role is `selectionText`
  when highlighted, `secondaryText` otherwise; its close icon's tint
  follows the same pair (`selectionText` / `tertiaryText`). Both roles are
  resolved by the theme's palette system, outside this component's own
  concern.
- **Border**: Not drawn — no border width, color, or bezel style other than
  the close button's own borderless-icon-button style appears anywhere in
  this concept.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  this concept.
- **Min/Max size**: A bar's thickness floor is `28pt` (top/bottom) or
  `140pt` (left/right), growing to the largest hosted item's preferred size
  on that axis plus `6pt` when that sum is larger
  (**thickness-grows-with-hosted-content**). A tab button has no explicit
  width/height constraint of its own; its size is whatever its content and
  fixed insets produce. The close button's hit area is a fixed `14×14pt`;
  its glyph (a circular X) renders at `10pt`, regular weight.

