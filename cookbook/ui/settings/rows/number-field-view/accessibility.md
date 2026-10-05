
- **Role/trait**: Not set explicitly anywhere in source. The field keeps
  its platform's default editable-text-field accessibility role; the label
  keeps the platform default for a non-editable field — a static-text
  element.
- **Label requirements**: Component MUST associate the field's accessible
  name with its label — the same row pattern the checkbox row and its
  siblings use — so the field's accessible name comes from its adjacent
  visible label rather than a separate accessibility-label string.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  there is no loading state, and disabling is left entirely to a caller
  (see States); a committed clamp or revert updates the field's text
  directly, which the field's own accessibility value reporting picks up
  automatically, with no explicit announcement call in source.
- **Minimum tap target**: Not applicable — this is a pointer/keyboard-driven
  control composition with no touch input path in source; the 44×44pt
  guidance is touch-specific. The field keeps its platform's regular
  control metrics; its clickable width is the fixed `fieldWidth` (72pt
  default) set by **fixes-field-width**.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The row label and the field's typed text both take their color from the theme's primary-text role (the field applies it in its theme observer), so contrast is whatever the active theme resolves against the settings-row background.

