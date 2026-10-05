
- **Corner radius**: Not applicable — the component adds no custom layer or
  drawing code; it only composes stock label and slider instances into a
  row.
- **Padding**: The row inserts a flexible spacer between the title label and
  the remaining elements and sets the row's spacing to 8pt, which applies to
  the label-to-spacer and slider-to-value-label gaps; the spacer-to-slider
  gap is explicitly zeroed, so the spacer's own width is the only thing
  between the title label and the slider. The row is pinned directly to the
  component's edges with no additional constant, so the component
  contributes 0pt of its own outer padding beyond that internal spacing.
- **Font**: Title label (button text role) resolves to 13pt, medium weight,
  proportional system font. Value label (caption text role — the default,
  since this component requests no monospaced digits) resolves to 11pt,
  regular weight, proportional system font. Both sizes scale with the
  active theme's size scale (1.0 by default) and both labels repaint
  automatically on a theme change.
- **Background**: None (transparent) — neither label draws a background,
  border, or bezel of its own, and neither the component nor the row
  container sets a background color of its own.
- **Foreground/Text**: Title label (primaryText color role) resolves to the
  active theme's foreground color at full strength. Value label
  (secondaryText color role) resolves to that same foreground dimmed 32%
  toward the background color, with a minimum contrast ratio of 3.0
  enforced. Both recompute live on a theme change.
- **Border**: Not applicable — no border is drawn or configured anywhere in
  source.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere in
  source.
- **Min/Max size**: The value label carries a fixed width constraint equal
  to the ceiling of the longest label width, computed once at
  initialization from the view model's choice labels (see
  fixes-value-label-width); no other element in the row has an explicit
  min/max constraint. Separately, once the component is added to a
  container, it activates a width constraint equal to that container's full
  width, at a priority just below the strictest available (see
  stretches-to-superview-width).

