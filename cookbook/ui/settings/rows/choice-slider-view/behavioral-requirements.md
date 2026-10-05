
- **arranges-row-layout**: Component MUST arrange the title label, the
  slider, and the value label in a single horizontal row, and MUST pin that
  row to the edges of the view.
- **builds-tick-marks-from-choices**: Component MUST, at initialization, set
  the slider's minimum to 0, its maximum to one less than the number of
  choices (floored at 0), its tick count to the number of choices, and MUST
  restrict the slider to landing only on those ticks.
- **flanking-labels-hug-tightly**: Component MUST prevent both the title
  label and the value label from expanding to absorb extra row width.
- **slider-expands-to-fill-remaining-width**: Component MUST expand the
  slider to absorb the row's leftover width, rather than the title label or
  the value label.
- **fixes-value-label-width**: Component MUST size the value label's width to
  a fixed constant equal to the ceiling of the widest rendered width, among
  the view model's choice-label strings, measured in the value label's own
  font (falling back to the current theme palette's caption font when the
  value label's font is unset).
- **initializes-from-view-model**: Component MUST, at the end of
  initialization, set the title label's text to the view model's title, and
  — when the view model's value matches a choice's value — set the slider
  to that choice's index and the value label's text to that choice's name.
- **claims-onchange-observer**: Component MUST assign its own handler to the
  view model's external-change notification during initialization, replacing
  any handler already registered there.
- **commits-slider-value**: Component MUST write the matching choice's value
  into the view model's setting observer when the slider is moved (see
  ignores-out-of-range-tick and skips-redundant-commits for the guard
  conditions).
- **ignores-out-of-range-tick**: Component MUST NOT write to the setting
  observer when the slider's rounded index falls outside the choice list's
  bounds.
- **skips-redundant-commits**: Component MUST NOT write to the setting
  observer when the resolved choice's value equals the current
  setting-observer value.
- **syncs-on-external-change**: Component MUST re-set the title label's text
  from the view model's title, and — when the view model's value matches a
  choice — re-set the slider and the value label's text, whenever the view
  model reports an external change.
- **leaves-display-unchanged-for-unmatched-value**: Component MUST NOT alter
  the slider's position or the value label's text when the view model's
  value does not match any choice's value, whether at initialization or on
  a later external-change notification.
- **exposes-constituent-views**: Component MUST expose the title label, the
  slider, and the value label as public, directly-accessible properties.
- **requires-view-model-at-construction**: Component MUST be constructible
  only with a view model supplied at construction time; construction paths
  that could produce an instance without one (e.g. a bare/default
  construction path or a serialization/decoding-based construction path)
  MUST be rejected (see Platform Notes for the mechanism the source uses).
- **stretches-to-superview-width**: Component MUST, once it is added to a
  container, activate a width constraint pinning itself to that container's
  full width, at a priority just below the strictest available.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

