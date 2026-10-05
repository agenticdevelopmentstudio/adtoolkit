
- **Corner radius**: Not applicable — the component has no layer or shape
  of its own.
- **Padding**: 0 around the component's own bounds — the stack is pinned
  to all four edges with no additional constant
  (**fills-bounds-with-zero-inset**). Internally, the gap between the
  title label and the caption view (when present) is the standard
  caption-spacing value; treat the 6pt current value as illustrative, not
  the assertion — the underlying token is the source of truth.
- **Font**: The title label uses the theme's heading text role
  (illustratively 15pt semibold, system font family, scaled by the active
  theme's size scale unless overridden — the token, not the literal, is
  the assertion). The caption's font is the theme's caption text role,
  applied by the caption view — see the Explanation View recipe for that
  view's own font details; this recipe does not duplicate them.
- **Background**: None/transparent — the component sets no background
  color or layer of its own, and neither the title label nor the caption
  view draws one either.
- **Foreground/Text**: The title label's text color tracks the theme's
  primary-text role, undimmed unlike the secondary-text role. The
  caption's text color is the theme's secondary-text role, applied by the
  caption view — see that recipe for its derivation and the open question
  it raises about that role's contrast.
- **Border**: None — no border is drawn or configured anywhere in this
  component.
- **Shadow**: None — no shadow is drawn or configured anywhere in this
  component.
- **Min/Max size**: None declared by the component itself. The title
  label keeps its default single-line, clipped configuration (the
  component never reconfigures its wrap settings), so it sizes to one
  non-wrapping line. The caption view, when present, wraps across as many
  lines as its width (matched to the stack's width) requires, per its own
  configuration.

