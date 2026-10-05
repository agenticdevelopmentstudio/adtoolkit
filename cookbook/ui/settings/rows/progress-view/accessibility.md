
- **Role/trait**: Not observable beyond the platform's defaults — no
  explicit accessibility role override appears in source. The indicator is
  a plain progress indicator, which the platform exposes to assistive
  technology with its own default progress-indicator role and value
  reporting.
- **Label requirements**: Not implemented in source — no line in source
  connects the indicator to the view model's title (a required,
  non-empty-guarded string describing what the progress represents).
  Every other row in this same family that carries a title (e.g. the
  checkbox row) links its control to that title for a screen reader; this
  component does not, so a screen reader announces only the platform's
  default progress-indicator role and current value, with no indication
  of what operation the progress belongs to.
- **Announce state changes (e.g., loading, disabled)**: Determinate ↔
  indeterminate transitions are carried entirely by the indicator's own
  determinate/value/animation state
  (**shows-determinate-bar-for-non-nil-progress**,
  **shows-indeterminate-animation-for-nil-progress**), which the platform
  surfaces to a screen reader through its own accessibility value
  reporting; no separate announcement call appears in source.
- **Minimum tap target**: Not applicable — the component defines no click
  handling of any kind; it is a purely visual, non-interactive display
  element with no tap target to size.

