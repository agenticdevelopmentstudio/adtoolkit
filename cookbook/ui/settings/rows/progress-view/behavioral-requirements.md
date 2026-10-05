
- **constructs-progress-indicator-at-regular-control-size**: The component
  MUST initialize the progress indicator at the platform's regular control
  size.
- **exposes-progress-indicator-publicly**: The component MUST expose the
  underlying progress indicator as a public, read-only property.
- **uses-constraint-based-layout**: The component MUST be positioned using
  layout constraints, not a legacy frame-based resizing mechanism, for both
  itself and the progress indicator (see Platform Notes for the exact
  mechanism).
- **adds-progress-indicator-as-subview**: The component MUST add the
  progress indicator as a child view of itself.
- **pins-progress-indicator-to-edges**: The component MUST pin the progress
  indicator's top, leading, trailing, and bottom edges to the corresponding
  edges of the view, with no additional inset.
- **reflects-initial-progress-value**: The component MUST reflect the view
  model's progress value immediately upon construction, before any further
  change to that value occurs.
- **tracks-progress-changes**: The component MUST update the progress
  indicator every time the view model's progress value changes, for as
  long as the view exists.
- **shows-determinate-bar-for-non-nil-progress**: WHEN the view model's
  progress value is present, the component MUST set the indicator to
  determinate, display that value, and stop any indeterminate animation.
- **shows-indeterminate-animation-for-nil-progress**: WHEN the view model's
  progress value is absent, the component MUST set the indicator to
  indeterminate and start its indeterminate animation.
- **continues-updates-while-retained**: The component MUST continue
  applying updates from **tracks-progress-changes** for as long as the
  view instance is retained (see Platform Notes for the exact subscription
  mechanism).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

