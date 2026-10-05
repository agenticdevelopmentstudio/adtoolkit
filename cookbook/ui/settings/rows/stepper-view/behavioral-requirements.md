
- **arranges-row-layout**: Component MUST arrange the label, the value
  label, and the stepper in that order in a single horizontal row and
  MUST pin that row to the edges of the view.
- **builds-label-from-view-model-title**: Component MUST build the label
  from the view model's title.
- **builds-value-label-monospaced**: Component MUST build the value
  label using a monospaced digit style.
- **resists-value-label-compression**: Component MUST set the value
  label's horizontal content compression resistance priority to
  required.
- **configures-stepper-bounds**: Component MUST set the stepper's
  minimum and maximum from the view model's minValue and maxValue.
- **fixes-stepper-increment**: Component MUST fix the stepper's
  increment at `1`, independent of the view model's range.
- **disables-stepper-wraparound**: Component MUST disable wraparound on
  the stepper.
- **initializes-stepper-value**: Component MUST set the stepper's value
  to the view model's value on construction.
- **initializes-value-label-text**: Component MUST set the value
  label's text to the string form of the view model's value on
  construction.
- **updates-value-label-on-change**: Whenever the stepper reports a
  change, component MUST set the value label's text to the string form
  of the stepper's new value, regardless of whether that value is
  committed.
- **commits-stepper-value**: Whenever the stepper reports a change and
  its new value differs from the view model's current value, component
  MUST write the new value into the view model's value.
- **skips-redundant-commits**: Component MUST NOT write to the view
  model's value when the stepper's new value equals its current value.
- **replaces-view-model-onchange**: Component's initializer MUST assign
  its own handler to the view model's change-notification callback,
  unconditionally replacing whatever handler (if any) was previously
  registered on that view model instance.
- **syncs-on-external-change**: Whenever the view model reports a
  change, component MUST re-set the label, the stepper's
  minimum/maximum, the stepper's value, and the value label's text from
  the view model.
- **exposes-constituent-views**: Component MUST expose the label, the
  stepper, and the value label as public, directly-accessible
  properties.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

Wiring the stepper's own change notification to the component, and
construction requiring a view model, are
platform-specific mechanics recorded under Platform Notes rather than as
normative requirements here — see wires-stepper-action,
rejects-coder-initialization, and rejects-frame-only-initialization.

