
- **Corner radius**: Not applicable — the component is a plain view with no
  custom layer, or corner-radius code, anywhere in source.
- **Padding**: 0 — the label is pinned directly to all four edges with no
  additional constant (**fills-container-bounds**).
- **Font**: the theme's `.caption` text role, which defaults to 11pt
  regular and scales with the active theme's size scale; not monospaced
  digits, since that option is not requested by this component and
  defaults to off.
- **Background**: None/transparent — the label draws no background or
  border of its own, and the view sets no background of its own.
- **Foreground/Text**: the theme's `.secondaryText` color role, which the
  theme derives as the foreground color dimmed 32% toward the background,
  with a minimum contrast ratio of 3.0 enforced.
- **Border**: None — no border is drawn or configured anywhere in this
  component.
- **Shadow**: None — no shadow is drawn or configured anywhere in this
  component.
- **Min/Max size**: None declared — no explicit width/height constraint is
  set on the label or the view. The label's shrink-to-fit behavior
  (**yields-width-to-container**) lets it shrink to whatever width its
  container gives it, with no floor; at a small enough width, the middle
  truncation will begin truncating into the caption prefix itself, not only
  the path (see Edge Cases).

