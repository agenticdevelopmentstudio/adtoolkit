
- **Role/trait**: Not customized in source — no explicit
  accessibility-role call appears anywhere in source. The stepper keeps
  the platform's built-in accessibility role for a stepper control; the
  label and value label keep the platform's default for a non-editable
  field — static-text elements.
- **Label requirements**: Not implemented in source. The stepper has no
  accessible name linked to the label — no accessibility-title linkage
  call appears anywhere in source. Every sibling row that pairs a label
  with an interactive control does link them — the checkbox row and the
  integer field row (via its wrapped number field row) both do the same
  — so the omission here is a plain gap against the row's own family
  pattern, not a documented design choice. A screen reader announces the
  stepper as an unlabeled control, and the value label's current number
  is a separate static text element rather than the stepper's own
  spoken value.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  there is no loading state, and disabling is left entirely to a caller
  (see States); a value change updates the stepper's value directly,
  which the platform's own native accessibility value reporting picks
  up, with no explicit announcement call in source. The value label's
  parallel text update is not itself linked to the stepper's
  accessibility value (see Label requirements, above).
- **Minimum tap target**: Not applicable — this is a pointer/
  keyboard-driven control composition with no touch input path in
  source; the 44×44pt guidance is touch-specific. No control-size
  override is set on the stepper, so it keeps the platform's regular
  system metrics.
- **minimum-contrast-ratio**: The component performs no contrast check of its own. The label takes the theme's primary-text role and the value label the theme's secondary-text role (at the monospaced code text style), both through the shared label factories, so contrast is whatever the active theme resolves.

