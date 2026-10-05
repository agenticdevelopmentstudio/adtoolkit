
- **arranges-heading-above-controls-stack**: Component MUST arrange the
  title label above a group of choice controls in a single outer, vertical
  container (label, then controls group), and MUST pin that outer
  container to the edges of the view.
- **builds-one-radio-button-per-choice**: Component MUST create one
  radio-type choice control for each entry in the view model's choices, in
  the same order, using that choice's label as the control's own visible
  text.
- **lays-out-controls-along-axis**: Component MUST arrange the created
  choice controls, in order, inside a single controls group whose layout
  orientation is set to the constructor's axis parameter (default
  vertical).
- **aligns-controls-stack-by-axis**: Component MUST align the controls
  group along its leading edge when axis is vertical, and along a shared
  first baseline when axis is not vertical.
- **spaces-stacks-by-row-spacing**: Component MUST set both the spacing
  between the label and the controls group, and the spacing between each
  control within the group, to the layout system's standard row spacing.
- **initializes-from-view-model**: Component MUST, at the end of
  initialization, set the label's text to the view model's title, and
  select the choice control whose associated value equals the view
  model's value while deselecting every other choice control.
- **commits-radio-selection**: Component MUST write the value paired with
  the choice control that fired the selection action into the view
  model's value whenever that value differs from the current value.
- **skips-redundant-commits**: Component MUST NOT write to the view
  model's value when the firing control's paired value equals the current
  value.
- **ignores-unmatched-sender**: Component MUST NOT write to the view
  model's value when the control that fired the selection action is not
  present in the component's recorded control-value pairs.
- **syncs-on-external-change**: Component MUST re-set the label's text
  from the view model's title, and re-select the choice control matching
  the view model's value while deselecting the rest, whenever the view
  model's change-notification callback fires.
- **exposes-constituent-views**: Component MUST expose the heading label
  and the ordered list of choice controls as public, directly-accessible
  properties; the choice-controls list MUST NOT be publicly replaceable as
  a whole (readable from outside the type, but not externally settable).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

