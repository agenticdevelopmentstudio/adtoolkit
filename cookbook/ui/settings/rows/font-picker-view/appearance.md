
- **Corner radius**: Not applicable - the component adds no custom layer or
  drawing code of its own; it only composes a label and a font chooser
  button into a row (see
  `adtoolkit://cookbook/ui/settings/rows/font-chooser-button` for the button's own
  corner treatment).
- **Padding**: The row inserts a flexible spacer between the label and the
  button and sets the row's spacing to the button role's default row
  spacing (8pt), which applies to the label-to-spacer gap; the
  spacer-to-button gap is explicitly zeroed, so the spacer's own width is
  the only thing between the label and the button. The row is pinned to
  the component's top/leading/trailing/bottom edges with no additional
  constant, so the component contributes 0pt of its own outer padding
  beyond that internal 8pt / 0pt spacing.
- **Font**: The label (button text role) resolves to that role's default
  style: 13pt, medium weight, proportional system font, scaling with the
  active theme's size scale and repainting on a theme change. The button's
  own font is dynamic and drawn at a fixed 12pt sample size regardless of
  the stored font's real size - see the sample-size requirement in
  `adtoolkit://cookbook/ui/settings/rows/font-chooser-button`.
- **Background**: None (transparent) for the label, and neither the
  component nor its row sets a background color of its own. The button's
  chrome is the font chooser button's own concern, not set here.
- **Foreground/Text**: The label (primaryText role) resolves to the active
  theme's foreground color at full strength, recomputed live on a theme
  change, then dimmed to 40% opacity when the row is disabled (see
  **dims-and-disables-the-row**). The button's title color is not set in
  this file; it is the font chooser button's stock text color.
- **Border**: Not applicable - no border is drawn or configured anywhere in
  source.
- **Shadow**: Not applicable - no shadow is drawn or configured anywhere in
  source.
- **Min/Max size**: Not applicable - no explicit min/max width or height
  constraint is set in source; sizing is governed entirely by the label
  and button's own intrinsic sizes inside the row (the button's own
  compression/hugging behavior when built without a fixed width is
  documented in `adtoolkit://cookbook/ui/settings/rows/font-chooser-button`).

