
- **Corner radius**: Not applicable — the component adds no custom layer
  or drawing code; it only composes a label and a slider into a row.
- **Padding**: The row layout inserts a flexible spacer between the label
  and the slider, with 8pt spacing between the label and the spacer, and
  0pt between the spacer and the slider, so the spacer's own width is the
  only thing between the label and the slider. The row is pinned directly
  to the component's edges with no additional constant, so the component
  contributes 0pt of its own outer padding beyond that internal 8pt / 0pt
  spacing.
- **Font**: The label resolves to the theme's button text role: 13pt,
  medium weight, proportional system font. The size scales with the
  active theme's size scale, and the label repaints automatically on a
  theme change.
- **Background**: None (transparent) — the label draws no background,
  border, or bezel, and neither the component nor its row container sets
  a background color of its own. The slider uses the platform's default,
  unconfigured rendering.
- **Foreground/Text**: The label resolves to the active theme's
  primary-text role at full strength, recomputed live on a theme change.
- **Border**: Not applicable — no border is drawn or configured anywhere
  in source.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere
  in source.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set in source; the slider's width is governed entirely by
  the horizontal content-hugging priority set at initialization, with no
  compression-resistance override on either subview.

