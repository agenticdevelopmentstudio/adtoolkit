
- **Corner radius**: Not applicable — the component draws no custom layer;
  any rounding on the popover's chrome comes from the platform's own default
  popover appearance, not from this component's view hierarchy.
- **Padding**: Root view: 8pt top/leading/trailing around the filter field;
  6pt gap between the filter field's bottom and the scroll container's top;
  8pt leading/trailing/bottom around the scroll container. Row label: 4pt
  leading/trailing inset from the cell's edges, centered vertically.
- **Font**: Row label uses the system font at the platform's small system
  font size for unmatched characters and a bold variant of the system font
  at the same size for characters matching the current filter text.
- **Background**: Not set explicitly anywhere in source; the root view,
  filter field, table, and scroll container all use their platform's default
  backgrounds.
- **Foreground/Text**: Not set explicitly anywhere in source; row labels use
  the platform's default label text color, with only font weight (regular
  vs. bold) varying by match state.
- **Border**: No border is drawn on the scroll container; no border is
  configured on the filter field or the table either.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  source.
- **Min/Max size**: The popover's content size and the root view's frame are
  fixed at 280×320pt (see fixed-content-size), the popover's one defined
  size constant, referenced elsewhere in this recipe by name rather than
  restated as a bare number; the single table column has a fixed width of
  248pt; no separate min/max constraint exists beyond these two fixed sizes.

