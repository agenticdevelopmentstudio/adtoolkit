
- **Role/trait**: The container view carries an accessibility identifier
  equal to `paneAccessibilityIdentifier` (set during the pane's initial
  load); it is a plain view with no explicit accessibility-role override in
  this file. The gear's "Move" menu item carries the identifier
  `pane.options.move`; each of its four submenu items carries
  `pane.options.move.<direction-name-lowercased>` (`left`, `right`, `up`,
  `down`). The arrange overlay's own controls (`composable-tabs.arrange.*`)
  are identified inside the arrange overlay itself, which this pane
  installs but does not itself label.
- **Label requirements**: Each move-menu item's icon carries an
  accessibility description equal to the direction's movement name
  ("Left", "Right", "Up", "Down"). The overlay's Add/Remove/Done buttons
  carry accessibility descriptions equal to their titles ("Add", "Remove",
  "Done"). The gear button's own "Pane Options" label comes from the
  shared pane chrome, not from this leaf pane.
- **Announce state changes**: The only explicit state-change announcement
  this component performs is a refusal announcement (default: a system
  beep) on every refused action — a blocked move, an Add with no choices,
  a Remove that is not currently legal. Neither an active-pane change nor
  arrange mode turning on or off posts any accessibility
  change-notification, so a screen reader user has no non-visual cue that
  the active pane changed or that arrange mode started or stopped.
- **Minimum tap target**: Not overridden in this file. The gear button and
  the overlay's Add/Remove/Move/Done buttons are standard buttons sized by
  the platform's default intrinsic content size; touch tap-target minimum
  guidance does not apply here, since this is a pointer/keyboard-driven
  toolbar rather than a touch surface, and this source sets no explicit
  minimum of its own.

