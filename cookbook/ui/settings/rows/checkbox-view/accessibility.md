
- **Role/trait**: Not customized beyond the title-element link below — no
  custom accessibility-role call appears in source; the toggle carries the
  platform's own built-in accessibility role for a switch/toggle control.
- **Label requirements**: Component MUST link the toggle's accessible name
  to the label — a bare switch otherwise has no name, so an assistive
  technology would announce it as an unlabelled control; the visible label
  supplies the accessible name instead of a separate accessibility-label
  string.
- **Announce state changes (e.g., loading, disabled)**: Not applicable — the
  component has no loading state and never disables itself in source (see
  States); on/off is announced by the toggle's own native accessibility
  value reporting when its state changes, which the component does not
  override.
- **Minimum tap target**: Not applicable — this is a pointer/trackpad-driven
  composition (no touch input path in source); a touch-target minimum is
  touch-interface guidance, not a pointer-interface requirement. The
  component sets no custom control size on the toggle, so it keeps the
  platform's regular system click-target metrics.
- **Keyboard operability**: The component sets no custom first-responder,
  key-handling, or focus-ring override on the toggle or label in source, so
  the toggle keeps its inherited tab order and its native Space/Return
  activation (see **inherits-native-keyboard-focus**).

