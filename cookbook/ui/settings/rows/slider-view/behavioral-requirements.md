
- **arranges-row-layout**: Component MUST arrange the title label and the
  slider in a single horizontal row, and MUST pin that row to the edges
  of the view.
- **sets-slider-range**: Component MUST set the slider's minimum and
  maximum bounds from the view model's minValue and maxValue at
  initialization.
- **slider-hugs-loosely**: Component MUST give the slider a horizontal
  content-hugging priority of `1` — below the row spacer's own low
  default priority — so the slider, not the inter-item spacing, takes the
  width left over after the label.
- **initializes-from-view-model**: Component MUST, at the end of
  initialization, set the label's text to the view model's title and the
  slider's value to the view model's value.
- **commits-slider-value**: Component MUST write the slider's new value
  into the view model's value whenever the slider reports a change and
  the new value differs from the view model's current value.
- **skips-redundant-commits**: Component MUST NOT write to the view
  model's value when the slider's new value equals its current value.
- **syncs-on-external-change**: Component MUST re-synchronize the
  label's text and the slider's minimum, maximum, and current value —
  re-reading the view model's title, minValue, maxValue, and value —
  whenever the view model reports a change.
- **exposes-constituent-views**: Component MUST expose the label and the
  slider as public, directly-accessible properties.

Construction requires a view model; every other construction path is
rejected, a platform mechanic rather than a normative requirement here — see rejects-coder-initialization and
rejects-frame-only-initialization under Platform Notes.

- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

