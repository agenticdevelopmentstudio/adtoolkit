
- **self-hiding-conformance**: Component MUST self-report its own
  visibility so a hosting group view can collapse a card row's padding and
  hairline once this component's content has hidden itself.
- **text-label**: Component MUST create its hint label using the
  caller-supplied hint text; the label wraps rather than truncates.
- **text-label-theming**: Component MUST set the hint label's text color
  to the current theme's secondary text color and its font to the current
  theme's caption text role, applied immediately at construction and
  re-applied on every subsequent theme change.
- **dismiss-button-title**: Component MUST create its dismiss button with
  a title equal to the caller-supplied button title.
- **dismiss-button-title-default**: Component MUST default the button
  title to `"Got It"` when the caller does not supply one.
- **dismiss-button-style**: Component MUST render its dismiss button in a
  small, rounded button style.
- **dismiss-button-action**: Component MUST wire its dismiss button so
  that clicking it invokes the component's dismiss handling.
- **stack-arrangement**: Component MUST arrange the hint label above the
  dismiss button in a vertical stack with leading alignment.
- **stack-spacing**: Component MUST set the vertical stack's spacing to
  the standard row spacing, 8pt.
- **dismissed-setting-observation**: Component MUST observe the
  caller-supplied dismissed-setting for changes, beginning at
  construction.
- **initial-visibility**: Component MUST set its shown/hidden state to the
  observed setting's current value at the end of initialization, before
  the view is ever displayed, without invoking the visibility-change
  callback.
- **visibility-update**: Component MUST update its shown/hidden state to
  the new value whenever the observed setting reports a change different
  from the component's current state.
- **visibility-write-guard**: Component MUST NOT change its shown/hidden
  state and MUST NOT invoke the visibility-change callback when the
  delivered value equals the component's current state.
- **visibility-change-notification**: Component MUST invoke the
  visibility-change callback exactly once, after its shown/hidden state
  has changed, each time a delivered value differs from the previous
  state.
- **visibility-change-callback**: Component MUST expose a
  visibility-change callback as a public, settable, optional property.
- **dismiss-persistence**: Component MUST set the observed setting's
  value to `true` whenever the dismiss button is clicked, unconditionally,
  regardless of the setting's current value.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

