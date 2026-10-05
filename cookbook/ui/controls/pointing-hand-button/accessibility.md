
- **Role**: Not set by this component; inherited from the platform's
  default button — no accessibility-role override appears in source.
- **Label**: Not set by this component; the accessible name follows the
  platform's own title-based naming, which this component never reads or
  writes.
- **Announce state changes**: Not applicable: this component introduces
  no state of its own beyond the standard button states (see States); the
  one behavior it does add — cursor shape on hover — is not a state the
  platform's accessibility APIs announce.
- **Keyboard navigation**: Inherited from the platform's default button
  unmodified — this component overrides no key-handling or focus method,
  so Tab/Shift-Tab focus movement and Space/Return activation follow the
  platform's native behavior.
- **Minimum tap target**: This component sets no control-size, width, or
  height of its own, so its click target is whatever the platform's
  regular-size system button computes for its title. This platform is
  pointer-driven, not touch-driven, so no minimum touch-target size
  applies here (see Compliance). Ports to touch platforms MUST give the
  equivalent control at least the platform minimum (44×44 pt on iOS,
  48×48 dp on Android, 40×40 epx on WinUI 3).

