
- **Corner radius**: Not applicable — the component adds no custom layer or
  drawing code; it composes stock text-field and label controls into a
  row.
- **Padding**: The row layout inserts a flexible spacer between the label
  and the field, sets the row's spacing to
  `SettingsLayout.default[.rowSpacing]` = 8pt (applied to the label→spacer
  gap), and zeroes the spacer→field gap — the same row shape and spacing
  math the checkbox row and the captioned slider row use. The row's own
  edge pinning (or the content-width variant used when `labelWidth` is set)
  adds 0pt of outer padding of its own beyond that internal 8pt/0pt
  spacing.
- **Font**: The label uses the button text role, resolving to 13pt, medium
  weight, proportional system font, scaled by the active theme's size
  scale. The field uses the code text role, resolving to 12pt, regular
  weight, the system monospaced font, also scaled by the size scale —
  chosen so a changing value doesn't reflow the field.
- **Background**: The label has none (transparent), drawing no background
  and no border of its own. The field is never given a transparent or
  borderless treatment; it keeps its platform's standard bezeled, opaque
  text-field background rather than being transparent like the label.
- **Foreground/Text**: The label resolves to the active theme's foreground
  color at full strength (the `.primaryText` role, unchanged from the
  theme's base foreground), repainted live whenever the theme changes. The
  field's text color is set directly to the same `.primaryText` role, also
  repainted live on every theme change.
- **Border**: The label has none. The field keeps its platform's default
  bezel/border rendering rather than one set by this component.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  this component.
- **Min/Max size**: The field's width is fixed to the constant `fieldWidth`
  (default `72`pt). The label's width is fixed only when `labelWidth` is
  supplied. No height constraint is set on either control; height comes
  from each control's intrinsic content size within the row.

