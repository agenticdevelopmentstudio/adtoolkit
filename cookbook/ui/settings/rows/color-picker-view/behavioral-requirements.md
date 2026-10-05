
- **arranges-row-layout**: Component MUST arrange the label and the color
  well into a single horizontal row, and MUST pin that row to all four
  edges of the view with no additional constant.
- **initializes-from-view-model**: Component MUST, during initialization,
  build the label from the view model's title and set the color well's
  color to the view model's color.
- **commits-color-value**: Component MUST set the view model's color to
  the color well's reported color every time the color well is changed,
  unconditionally, with no comparison against the current value.
- **delegates-color-clamping**: Component MUST NOT perform its own
  clamping or validation of the reported color before writing it to the
  view model's color; normalizing an out-of-gamut or malformed color is
  the color storage type's responsibility, one layer below this
  component.
- **syncs-on-external-change**: Component MUST re-set the label's text to
  the view model's title and the color well's color to the view model's
  color whenever the view model reports an external change.
- **owns-on-change**: Component MUST assign its own handler to the view
  model's external-change notification during initialization,
  unconditionally replacing any handler already registered on that view
  model instance; callers MUST NOT share a single view model across more
  than one observer (for example, two instances of this component, or an
  instance of this component and another registered external-change
  handler), because constructing the later observer silently drops
  whichever handler was registered first.
- **exposes-constituent-views**: Component MUST expose the label and the
  color well as public, directly-accessible, read-only properties.
- **requires-view-model-at-construction**: Component MUST be constructible
  only with a view model supplied at construction time; construction paths
  that could produce an instance without one (e.g. a bare/default
  construction path or a serialization/decoding-based construction path)
  MUST be rejected (see Platform Notes for the mechanism the source uses).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

