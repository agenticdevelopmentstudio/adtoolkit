
- **Role/trait**: Not set explicitly anywhere in source. The text field
  keeps the platform's default editable-text-field accessibility role; the
  label keeps the platform's default for a non-editable field (set
  non-editable explicitly) — a static-text element.
- **Label requirements**: Component MUST link the text field's accessible
  name to the adjacent visible label — the same row pattern several
  sibling row controls in this system use — so the field's accessible name
  comes from that label rather than a separate accessibility-label string.
- **Announce state changes (e.g., loading, disabled)**: Not applicable —
  there is no loading state, and disabling is left entirely to a caller
  (see States); a committed clamp or revert updates the text field's
  displayed value directly, which the platform's own accessibility value
  reporting picks up automatically, with no explicit announcement call in
  source.
- **Minimum tap target**: Not applicable — this is a pointer/keyboard-driven
  composition with no touch input path in source; the 44×44pt guidance is
  touch-specific. No non-default control size is set on the text field, so
  it keeps the platform's regular system metrics; its clickable width is
  the fixed field width (52pt default here, per **default-field-width**),
  constrained onto the wrapped field's own width by the wrapped view's own
  fixed-width requirement (see
  `adtoolkit://cookbook/ui/settings/rows/number-field-view#requirements/fixes-field-width`).

