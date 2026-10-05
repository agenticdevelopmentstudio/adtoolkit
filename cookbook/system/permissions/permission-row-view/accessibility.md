
- Role/trait: the row itself is a plain view; the component deliberately
  never marks it as an accessibility element (documented in source as an
  intentional omission). The action button is a standard button (role
  button), the only accessibility element this component contributes per
  row.
- Label requirements: the action button's accessible label comes from its
  own title (the permission's action title, or `"Open Settings"`); the
  component sets no separate accessibility label on the button, the row,
  or the status text.
- Identifier: the action button's accessibility identifier is set to a
  value derived from the permission's own stable identifier token (see
  action-button-has-stable-identifier), so a UI test can address it per
  permission; the row and its other subviews (icon, title, description,
  status dot/label) receive no accessibility identifier.
- Announce state changes: a status-apply call updates the status label's
  displayed text with a plain assignment; this component never explicitly
  posts an accessibility change notification anywhere in source, so it
  does not itself announce a status change to assistive technology.
- Minimum tap target: not applicable in the touch sense — this is a
  pointer-driven control on a desktop platform, and touch minimum-target
  guidance does not apply here. The action button's compact sizing is the
  platform's own system-determined click target, not measured or floored
  by this component.
- **contrast**: Title, description and status text sit over the card's near-transparent white overlay (3%/6% alpha), composited over whatever background the host window supplies. The component performs no contrast check of its own, and the effective background is not fixed, so whether the combination meets 4.5:1 (3:1 for large text) per `agenticdevelopercookbook://guidelines/cookbook/ui/platform-design-languages` is unverified.

