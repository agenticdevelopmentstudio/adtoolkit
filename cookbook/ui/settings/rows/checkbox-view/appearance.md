
- **Corner radius**: Not applicable — the component adds no custom layer or
  drawing code; it only composes a stock label and a stock toggle control
  into a row.
- **Padding**: The row inserts a flexible spacer between the label and the
  toggle and sets the row's spacing to 8pt, which applies to the
  label-to-spacer gap; the spacer-to-toggle gap is explicitly zeroed, so the
  spacer's own width is the only thing between the label and the toggle. The
  toggle keeps its own default higher expansion priority (higher than the
  spacer's), so the spacer, not the toggle, absorbs the row's leftover
  width. The row is pinned directly to the component's edges with no
  additional constant, so the component contributes 0pt of its own outer
  padding beyond that internal 8pt / 0pt spacing.
- **Font**: The label (button text role) resolves to 13pt, medium weight,
  proportional system font. The size scales with the active theme's size
  scale (1.0 by default) and the label repaints automatically on a theme
  change. The toggle draws no text of its own.
- **Background**: None (transparent) — the label draws no background,
  border, or bezel, and neither the component nor the row container sets a
  background color of its own.
- **Foreground/Text**: The label (primaryText color role) resolves to the
  active theme's foreground color at full strength, recomputed live on a
  theme change. The toggle's on/off track and thumb colors are the
  platform's own system rendering; the component sets no color on the
  toggle.
- **Border**: Not applicable — no border is drawn or configured anywhere in
  source.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  source.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set in source; sizing is governed entirely by the label's
  and the toggle's own intrinsic content sizes, the row's 8pt spacing, and
  the row's edge pinning.

