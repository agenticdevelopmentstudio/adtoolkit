
- **Corner radius**: Not applicable — the component adds no custom layer
  or drawing code; it only composes a stock label and stock radio-button
  controls into two nested groups.
- **Padding**: Component does not use the shared row-composition helper
  its sibling rows use (no spacer, no forced content-hugging priorities).
  The outer group ([label, controls group]) is vertical, aligned to its
  leading edge, with spacing set to the layout system's standard row
  spacing (8pt). The controls group itself uses the same 8pt spacing,
  applied between each radio button along whichever axis it is laid out
  on. The outer group's top/leading/trailing/bottom edges are pinned
  directly to the component's edges with no additional constant, so the
  component contributes 0pt of its own outer padding beyond that internal
  8pt spacing.
- **Font**: The heading label uses the button text role, resolving to
  13pt, medium weight, proportional system font, scaling with the active
  theme's size scale and repainting automatically on a theme change. Each
  radio button's own title text, by contrast, comes from the platform's
  stock radio-button factory, not from the app's themed label — it renders
  in the platform's native control font and does not participate in the
  app's theme size-scale or repaint-on-theme-change path the heading label
  uses.
- **Background**: None (transparent) — the heading label draws no
  background or border of its own; neither the view nor either group sets
  a background color of its own. Each radio button's background is the
  platform's native, unthemed rendering.
- **Foreground/Text**: The heading label (`.primaryText` role) resolves to
  the active theme's foreground color at full strength, recomputed live on
  a theme change. Each radio button's title text color is the platform's
  own system rendering; this component sets no color on any radio button.
- **Border**: Not applicable — no border is drawn or configured anywhere
  in this component.
- **Shadow**: Not applicable — no shadow is drawn or configured anywhere
  in this component.
- **Min/Max size**: Not applicable — no explicit min/max width or height
  constraint is set in source; sizing is governed entirely by the label's
  and each radio button's own intrinsic content size, the two groups' 8pt
  spacing, and the outer group's edge pinning.

