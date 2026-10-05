
- **Corner radius**: `4pt` on each tab button's background pill.
- **Padding**: Inside a tab button: `10pt` leading from the background to
  the title label, `4pt` top/bottom between the label and the background,
  `6pt` between the label and the close button, `6pt` from the close button
  to the background's trailing edge, and the background itself is inset
  `2pt` from the button's own top/bottom. Inside a tab bar: `6pt` between an
  item and the bar's outer (window) side only — the content (workspace)
  side is flush; `8pt` at each end of the bar along its length, overridable
  per edge; `4pt` between items on a horizontal bar, or `-16pt` (a negative
  gap) between items on a vertical bar.
- **Font**: The `caption` text role (size and weight resolved by the active
  theme's typography, not a fixed point size) for a tab button's title
  label.
- **Background**: A tab bar fills with the `windowBackground` palette
  role. The shared content area fills with the configured background-color
  override when set, or the `windowBackground` role when not. A tab
  button's background is the `selection` role when selected, or transparent
  when not.
- **Foreground/Text**: A tab button's title label uses the `selectionText`
  role when selected or `secondaryText` when not; its close icon tints
  `selectionText` when selected or `tertiaryText` when not.
- **Border**: The shared content area draws a `1pt` border in the
  configured outline-color override when set, or the theme's `outline` role
  when not. No tab button or bar itself draws a border.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  this concept.
- **Min/Max size**: A bar's thickness floor is `28pt` (top/bottom) or
  `140pt` (left/right), and grows to the largest hosted item's preferred
  size on that axis plus `6pt` when that is larger. The close button's hit
  area is a fixed `14×14pt`; its glyph (a circular X) renders at `10pt`,
  regular weight.

