
- **Corner radius**: Not applicable — the component adds no custom layer
  or drawing code; it only composes stock text and slider controls into a
  row.
- **Padding**: The row's layout inserts a flexible gap between the title
  label and the remaining controls, using the settings row-spacing design
  token (currently 8pt) between label and gap and between slider and
  caption, while zeroing the gap between the flexible spacer and the
  slider — so the spacer's own width is the only space between the label
  and the slider. The row is pinned to all four edges of the component
  with no additional constant, so the component contributes 0pt of its own
  outer padding beyond that internal spacing (see Platform Notes for the
  mechanism the source uses).
- **Font**: Title label uses the button text role; caption label uses the
  code text role. Neither role's size or weight is set by this component
  — the theme's typography owns the resolved point size and weight per
  role, currently 13pt medium, proportional system font for the button
  role, and 12pt regular, monospaced for the code role. Both sizes scale
  with the active theme's size scale (1.0 by default) and both labels
  repaint automatically on a theme change.
- **Background**: None (transparent) — neither the title nor caption
  label draws a background, border, or bezel of its own, and the
  component draws no background color of its own either.
- **Foreground/Text**: Title label uses the primaryText color role;
  caption label uses the secondaryText color role. Neither color is
  computed by this component — the theme's palette owns both:
  primaryText currently resolves to the active theme's foreground color
  at full strength, and secondaryText currently resolves to that same
  foreground dimmed 32% toward the background color with a minimum
  contrast ratio of 3.0 enforced. Both recompute live on a theme change.
- **Border**: Not applicable — no border is drawn or configured anywhere.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set; sizing is governed entirely by the slider expanding
  to fill remaining width and the caption never being compressed (see
  **slider-expands-to-fill-remaining-width** and
  **caption-never-compressed**).

