
- **Corner radius**: Not applicable — the component adds no custom layer
  or drawing code; it only composes a stock label and a stock color-well
  control into a row.
- **Padding**: The row inserts a flexible spacer between the label and the
  color well and sets the row's spacing to 8pt, which applies to the
  label-to-spacer gap; the spacer-to-color-well gap is explicitly zeroed,
  so the spacer's own width is the only thing between the label and the
  color well. The row is pinned directly to the component's edges with no
  additional constant, so the component contributes 0pt of its own outer
  padding beyond that internal 8pt / 0pt spacing.
- **Font**: The label (button text role) resolves to 13pt, medium weight,
  proportional system font, scaling with the active theme's size scale and
  repainting on a theme change. The color well has no text of its own —
  not applicable.
- **Background**: None (transparent) for the label — it draws no
  background, border, or bezel of its own — and neither the component nor
  the row container sets a background color of its own. The color well's
  swatch chrome is the platform's own default rendering, not customized in
  source.
- **Foreground/Text**: The label (primaryText color role) resolves to the
  active theme's foreground color at full strength, recomputed live on a
  theme change. The color well is not a text control; the color it
  displays is the edited value itself, not a foreground/text color, so
  "Foreground/Text" is not applicable to it.
- **Border**: Not applicable — no border is drawn or configured anywhere
  in source; the color well's border is the platform's stock chrome, not
  custom to this file.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere
  in source.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set in source; sizing is governed entirely by the label's
  and the color well's own intrinsic sizes inside the row container.

