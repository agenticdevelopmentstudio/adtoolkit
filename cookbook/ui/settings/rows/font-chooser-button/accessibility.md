
- **Role**: Button, inherited from the underlying control; the component
  sets no custom accessibility role.
- **Label**: The accessible name is the title, set by the caller. The
  caller owns the wording because only it knows what the font means where
  it is stored — the source's own doc comment gives `"System"` for a role
  with no family of its own and `"Menlo — 14 pt (not installed)"` for a
  face the machine lacks, so the accessible name already carries
  availability information when the caller supplies it.
- **Announce state changes**: Not applicable — the component defines no
  disabled or loading state of its own (see States); if a caller disables
  the button directly, the enabled/disabled announcement is the platform
  control's native behavior, not something this component implements.
- **Keyboard navigation**: Inherited from the underlying control — the
  primary activation key activates the button through the wiring set up
  at construction; the component sets no secondary key equivalent, so a
  confirm/return key does not activate it. Tab/Shift-Tab-style focus
  movement onto and off the button follows the platform's own keyboard-
  navigation defaults. The resulting font-selection UI is a separate,
  standard platform surface; its own keyboard navigation is not
  implemented in this file.
- **Minimum tap target**: This is a pointer/trackpad-driven control on its
  source platform; source sets no size override, so the click target is
  the regular-size control sized to its title, per that platform's design
  guidance for pointer-driven controls. Ports to touch platforms MUST give
  the equivalent control at least the platform minimum: 44 by 44 pt on
  iOS, 48 by 48 dp on Android, 40 by 40 effective pixels on WinUI 3.

