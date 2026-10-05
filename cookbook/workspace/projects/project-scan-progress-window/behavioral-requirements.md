
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **fixed-panel-geometry-and-style**: construction MUST give the panel a
  content size of 240 by 72 points and a chrome style of a titled,
  utility-style window.
- **panel-title**: construction MUST set the panel's title to "Scanning".
- **floating-non-modal-presentation**: construction MUST make the panel a
  floating, non-modal panel; nothing exposed by this component presents it
  modally.
- **deactivation-visibility**: construction MUST leave the panel visible
  when the host application becomes inactive, rather than hiding it on
  deactivation.
- **key-only-if-needed**: construction MUST configure the panel so it
  becomes the focused window only if something inside it actually requires
  focus, never simply by being shown.
- **centered-on-screen**: construction MUST center the panel on the screen
  that contains it.
- **automation-identifiers-assigned**: construction MUST assign the
  automation identifier "project-scan.window" to the panel, and MUST assign
  the automation identifier "project-scan.headline" to the headline label.
- **initial-headline-text**: the headline label MUST be initialized with
  the literal string "Scanning for projects…".
- **initial-progress-bar-state**: the progress indicator MUST be
  initialized as an indeterminate bar at a small control size, animated on
  its own thread, with a value range of 0 to 1.
- **present-starts-animation-and-orders-front**: presenting MUST start the
  progress indicator's animation and MUST bring the window to the front
  without making it the focused (key) window.
- **present-guards-missing-window**: presenting MUST do nothing — MUST NOT
  start the animation or bring anything to the front — when the panel's
  window no longer exists.
- **finish-completes-progress-bar**: finishing MUST stop the progress
  indicator's animation, MUST switch it to a determinate state, and MUST
  set its value to its maximum.
- **finish-updates-headline-text**: finishing MUST set the headline text to
  the literal string "Scan complete".
- **finish-schedules-delayed-close**: finishing MUST schedule the panel to
  close on the main thread after exactly the linger duration (1.0 second)
  has elapsed.
- **finish-outlives-caller-reference**: the scheduled close MUST keep the
  panel itself alive until it fires, even if every other reference to the
  instance has already been released by the time it runs.

