
- **renders-title-from-permission**: The component MUST set its title
  label's text to the permission's display name, except for the Automation
  permission, where it MUST append `" — "` plus the target's resolved
  application name (or the raw bundle identifier when that resolution
  fails).
- **renders-description-from-permission**: The component MUST set its
  description label's text to the permission's explanation, resolving an
  Automation target's name the same way as the title.
- **renders-icon-from-permission**: The component MUST show an icon view
  with the symbol named by the permission's icon name, at point size 16,
  weight regular, tinted the secondary label color.
- **initial-status-is-checking**: The component MUST display `"Checking…"`
  in the status label before a refresh completes for the first time.
- **refresh-queries-checker**: Refreshing MUST call the injected status
  checker for the permission and, unless the underlying asynchronous work
  was cancelled while awaiting the result, MUST update the status dot's
  color, the status label's text and color, and the action button's title
  from the result.
- **cancelled-refresh-does-not-apply**: If a refresh's underlying
  asynchronous work is cancelled before the status checker returns, the
  component MUST leave its displayed status, dot color, and button title
  unchanged.
- **granted-status-appearance**: The component MUST show the status dot
  colored with the success color and the status label reading `"Granted"`
  in the success color when the status checker resolves to granted.
- **denied-status-appearance**: The component MUST show the status dot
  colored with the warning color and the status label reading
  `"Not Granted"` in the warning color when the status checker resolves to
  denied.
- **undetermined-status-appearance**: The component MUST show the status
  dot colored with the secondary label color and the status label reading
  `"Unknown"` in the secondary label color when the status checker resolves
  to undetermined.
- **status-conveyed-by-text-and-color**: The component MUST convey grant
  status through the status label's text in addition to the status dot's
  color, in every one of the three states above, so status is never
  communicated by color alone.
- **granted-button-title**: The component MUST set the action button's
  title to `"Open Settings"` whenever the most recently applied status is
  granted.
- **ungranted-button-title**: The component MUST set the action button's
  title to the permission's own action title whenever the most recently
  applied status is denied or undetermined.
- **button-width-fits-widest-title**: The component MUST size the action
  button to a fixed width equal to the widest fitting width across every
  possible action title, measured once per process with a sizing probe
  matching the real action button's own style and size.
- **action-carries-displayed-status**: Pressing the action button MUST
  invoke the configured action handler with the permission and whatever
  status was applied by the most recent status-apply call, not a freshly
  re-read status.
- **pre-refresh-action-enabled**: The component MUST NOT disable the
  action button before the first refresh completes; the component's
  layout-building step never disables it, so pressing it before that point
  MUST invoke the action handler with the permission and the displayed
  status's initial value, undetermined.
- **keyboard-activates-action**: The action control MUST be reachable by
  keyboard focus and activatable with the primary activation keys
  (Space/Return).
- **test-observable-surface**: Beyond a small, deliberately exposed set of
  test seams (the displayed status text, the displayed action-button
  title, and a test-only trigger for the action), no other internal state
  of the component is exposed for testing. A test MUST reach the title,
  description, icon, and status-dot views by walking the component's own
  public view hierarchy, or by reading its publicly inherited visual layer
  for card-appearance assertions.
- **action-button-has-stable-identifier**: The action button MUST set its
  accessibility identifier to a value derived from the permission's own
  stable identifier token, in the form `"permission.<token>.action"`.
- **row-has-no-accessibility-identifier**: The row view itself MUST NOT set
  an accessibility identifier and MUST NOT become an accessibility element;
  the action button is the only per-permission accessibility handle.
- **minimum-row-height**: The component MUST maintain a height of at least
  72pt.
- **card-appearance**: The component MUST render with a backing layer, an
  8pt corner radius, a background of white at 3% opacity, and a 0.5pt
  border of white at 6% opacity.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

