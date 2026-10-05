
- Role: a native label and text input pairing (no special input type is
  set, so it defaults to a plain text field).
- Label requirement: satisfied unconditionally — the label is a required
  input and is always rendered associated with the input's identifier
  (**renders-associated-label**).
- Announce state changes: the input's invalid state is toggled on when
  an error is set and is otherwise absent
  (**marks-input-invalid-on-error**, **omits-invalid-attribute-without-error**);
  the disabled state maps to the native disabled state, which assistive
  technology announces natively.
- **minimum-tap-target-unverified**: the input's fixed height is 36px, with no minimum width
  enforced beyond filling its row; the component performs no touch-target check of its own, and
  whether it meets or is exempt from a 44x44 touch-target guideline has not been measured against
  the platform's guideline (see the referenced platform-design-languages guidance).
- Error announcement to assistive technology: not linked. The shared
  footnote component accepts an identifier specifically so a caller can
  point the field's description at the rendered error text, but the
  editor never supplies that identifier to the footnote nor forwards a
  description link to the input. A screen-reader user hears the invalid
  state but has no programmatic link to the error message itself
  (tracked as a pending Design Decision below).
- **minimum-contrast-ratio-unverified**: the prefix's muted-text color role on the field background
  resolves at runtime from the theme's semantic role variables; the component performs no contrast
  check of its own, and whether the pairing meets a minimum contrast ratio for small text depends on
  the resolved token values.
- Differentiate without color: satisfied — the invalid state is conveyed
  by the error text itself (**shows-error-in-place-of-hint** swaps in the
  error message, not just a color change) and by the invalid-state
  marker, not by border/ring color alone.

