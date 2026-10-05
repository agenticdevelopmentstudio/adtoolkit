
- **Role/trait**: Not observable beyond the platform's defaults — no
  explicit accessibility role is set. The field carries a test identifier
  (`extension-input-box.field`), which is an identifier for UI testing,
  not a role or label. The field carries the platform's built-in
  text-field accessibility role automatically.
- **Label requirements**: Nothing explicitly links the field to the title
  or prompt as its accessibility label; a screen reader announces only
  whatever the platform derives on its own when focus lands in the field —
  the field has no text-derived label of its own beyond its placeholder.
- **Announce state changes (e.g., loading, disabled)**: Not applicable for
  Disabled — the component never disables itself (see States). For the
  validation message: `showValidation(_:)` toggles its visibility and
  text with no explicit accessibility change notification of its own; any
  screen-reader announcement of the change comes from the platform's own
  default behavior on visibility/text changes, not from an explicit call
  this component makes.
- **Minimum tap target**: Not applicable — this component targets
  pointer/trackpad input, not touch; the 44×44pt minimum is
  touch-interface guidance, not a pointer-interface requirement.

