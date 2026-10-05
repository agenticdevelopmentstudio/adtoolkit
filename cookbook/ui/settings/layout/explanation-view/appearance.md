
- **Corner radius**: Not applicable — the view has no shape or layer of its
  own.
- **Padding**: 0 — the label is pinned directly to all four edges with no
  additional constant (`fills-view-edge-to-edge`).
- **Font**: the theme's `.caption` text role, which defaults to 11pt
  regular and scales with the active theme's size scale; not monospaced by
  default.
- **Background**: None/transparent — the label draws no background of its
  own, and the view sets no background of its own.
- **Foreground/Text**: the theme's `.secondaryText` color role, derived as
  the foreground color dimmed 32% toward the background, with a minimum
  contrast ratio of 3.0 enforced.
- **Border**: None — no border is drawn or configured anywhere.
- **Shadow**: None — no shadow is drawn or configured anywhere.
- **Min/Max size**: None declared — no explicit width/height constraint is
  set. The label's loose horizontal priorities let its width shrink to
  whatever the container gives it, while its required vertical priority
  lets its height grow to fit however many lines wrapping produces.

