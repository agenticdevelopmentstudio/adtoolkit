
- **Role/trait**: Not observable beyond the platform's defaults — no
  explicit accessibility role override appears. The label is the platform's
  standard read-only text element, which is exposed to assistive technology
  as static text by default.
- **Label requirements**: Satisfied unconditionally — the label always
  carries the exact `text` argument passed at construction
  (`renders-caller-text`); it reads empty only if the caller passes an
  empty string.
- **Announce state changes (e.g., loading, disabled)**: Not applicable — the
  component has no loading or disabled state to announce (see States).
  Callers reassign the label's text directly, and the platform's standard
  accessibility support for a text element reflects that change without any
  further code in this view.
- **Minimum tap target**: Not applicable — the view defines no
  target/action, gesture recognizer, or click handling; this is a purely
  visual, non-interactive display element with no tap target to size.
- **minimum-contrast-ratio**: The label's color MUST come from the theme's
  secondary-text role at the caption text size, and the component MUST NOT
  perform any contrast check or adjustment of its own. The theme's dimming
  formula enforces only a 3.0 minimum contrast ratio for that role, while
  the 11pt caption size falls under WCAG 2.1's small-text criterion (1.4.3)
  that calls for 4.5:1; whether a given theme's resolved
  secondary-text-on-background pair reaches 4.5:1 is determined by that
  theme's colors, not by this component.

