
- **Role/trait**: Not explicitly set anywhere in source; the Add/Remove/Done
  buttons, the Move menu, and the pane-name label all use the platform's
  default roles for a button, a pop-up menu, and a text field respectively.
- **Label requirements**: The root view and every control carry an explicit
  accessibility identifier for automation (`composable-tabs.arrange.scrim`,
  `.add`, `.remove`, `.move`, `.done`, and one `.move.<direction>` per Move
  item). Each button's image is given an accessibility description equal to
  its title (`Add`, `Remove`, `Done`, and each Move item's movement name),
  and each control's own visible title text is otherwise the label the
  platform exposes to a screen reader by default; source sets no separate
  label override beyond that.
- **Announce state changes**: Not implemented. Refreshing availability
  changes the enabled state of the Add, Remove, and Move controls (e.g.
  disabling Remove because the pane is now the last one, or disabling a
  Move direction because the pane reached the top of the window) without
  any accessibility change-notification call anywhere in this file, so a
  screen reader user hears nothing about the change until they navigate
  back onto the affected control.
- **Minimum tap target**: Each button uses the platform's standard button
  style with no explicit frame set in source, so its height comes from the
  platform's default intrinsic content size rather than a literal point
  value in this file; that default is well under touch tap-target minimums,
  which is expected for a pointer/keyboard-driven toolbar rather than a
  touch surface. Touch tap-target minimum guidance applies to the
  touch-platform translations described in Platform Notes, not to this
  view.

