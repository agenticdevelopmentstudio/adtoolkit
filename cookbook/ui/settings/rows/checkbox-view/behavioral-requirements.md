
- **arranges-row-layout**: Component MUST arrange the title label and the
  toggle in a single horizontal row (label, then toggle), MUST place the
  toggle at the row's trailing edge with a flexible spacer absorbing the
  leftover width between the label and the toggle, and MUST pin that row to
  the edges of the view.
- **links-toggle-accessibility-title**: Component MUST link the toggle's
  accessible name to the label, so the toggle is announced with the label's
  text rather than as an unlabelled control.
- **initializes-from-view-model**: Component MUST, at the end of
  initialization, set the label's text to the view model's title and the
  toggle's state to on when the view model's value is true and off when it
  is false.
- **commits-toggle-value**: Component MUST write the toggle's new boolean
  value into the view model's setting observer whenever the toggle is
  activated and the new value differs from the current setting-observer
  value.
- **skips-redundant-commits**: Component MUST NOT write to the setting
  observer when the toggle's new value equals the current setting-observer
  value.
- **syncs-on-external-change**: Component MUST re-set the label's text to
  the view model's title and the toggle's state to reflect the view model's
  value whenever the view model reports an external change.
- **exposes-constituent-views**: Component MUST expose the label and the
  toggle as public, directly-accessible properties.
- **requires-view-model-at-construction**: Component MUST be constructible
  only with a view model supplied at construction time; construction paths
  that could produce an instance without one (e.g. a bare/default
  construction path or a serialization/decoding-based construction path)
  MUST be rejected (see Platform Notes for the mechanism the source uses).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **claims-sole-onchange-observer**: Component MUST assign its own handler
  to the view model's external-change notification during initialization,
  superseding any handler already registered on that view model instance
  (see **overwritten external observer** in Edge Cases).
- **inherits-native-keyboard-focus**: Component MUST NOT override the
  toggle's or the label's default focus, tabbing, or key-handling behavior;
  no custom first-responder, key-handling, or focus-ring override appears in
  source, so keyboard operability follows the platform's native toggle
  control behavior unchanged.

