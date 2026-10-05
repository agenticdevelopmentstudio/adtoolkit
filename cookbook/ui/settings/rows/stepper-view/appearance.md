
- **Corner radius**: Not applicable — the component adds no custom layer
  or drawing code; it only composes two text labels and a stepper
  control into a row.
- **Padding**: The row layout, given three elements (label, value label,
  stepper), inserts its flexible spacer after the first — between the
  label and the value label, not between the value label and the
  stepper (arranged order becomes label, spacer, value label, stepper).
  The row's default spacing is 8pt, applied between every adjacent pair;
  the spacer's own gap to the value label is zeroed, leaving the
  value-label-to-stepper gap at the unmodified default 8pt. The visible
  effect is the label pinned to the row's leading edge, all of the row's
  leftover width absorbed in the flexible gap right after it, and the
  value label/stepper sitting together, 8pt apart, at the trailing edge.
  The row is pinned to the component's edges with 0pt of additional
  outer padding beyond that.
- **Font**: The label resolves to the theme's button text role: 13pt,
  medium weight, proportional system font, scaled by the active theme's
  size scale. The value label resolves to the theme's code text role:
  12pt, regular weight, the system monospaced font, also scaled by the
  size scale — chosen so a value that changes on every click doesn't
  reflow the row. Both repaint automatically on a theme change. The
  stepper draws no text of its own.
- **Background**: The label/value label — none (transparent); neither
  draws a background, border, or bezel. The stepper — no background is
  set in source; it keeps the platform's default up/down control
  appearance.
- **Foreground/Text**: The label resolves to the active theme's
  primary-text role at full strength. The value label resolves to the
  theme's secondary-text role, a lower-emphasis color than the label.
  Both are recomputed live on a theme change. The stepper's arrow tint
  is the platform's own system rendering; the source sets no color on
  it.
- **Border**: Not applicable — the label/value label draw no border; the
  stepper keeps the platform's default bezel, drawn by the system
  rather than configured in source.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere
  in source.
- **Min/Max size**: Not applicable — no explicit width/height constraint
  is set on the label, value label, or stepper beyond the value label's
  compression-resistance priority (not a size constraint); sizing
  follows each control's own intrinsic content size, the row's spacing
  math, and the row-pinning.

