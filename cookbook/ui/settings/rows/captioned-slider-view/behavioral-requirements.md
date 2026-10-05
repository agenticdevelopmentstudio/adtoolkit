
- **arranges-row-layout**: Component MUST arrange the title label, the
  slider, and the caption label in a single horizontal row, and MUST pin
  that row to the edges of the component.
- **sets-slider-range**: Component MUST set the slider's minimum and
  maximum from the view model's minimum and maximum at initialization.
- **does-not-validate-range**: Component MUST NOT validate or correct the
  view model's minimum/maximum before assigning them to the slider; an
  inverted or zero-width range is passed through unmodified.
- **slider-expands-to-fill-remaining-width**: Component MUST let the
  slider take up whatever width the row has left over after the title
  label and caption are laid out, rather than that leftover width going to
  the inter-item spacing (see Platform Notes for the mechanism the source
  uses).
- **caption-never-compressed**: Component MUST never compress the caption
  label below the width its text needs.
- **caption-uses-monospaced-digits**: Component MUST render the caption
  label with monospaced digit glyphs, so the caption's width does not
  jitter as its digits change.
- **initializes-from-view-model**: Component MUST, at the end of
  initialization, set the title label's text to the view model's title,
  the slider's value to the view model's value, and the caption label's
  text to the formatter applied to the view model's value.
- **updates-caption-live**: Component MUST update the caption label's text
  to the formatter applied to the new value immediately whenever the
  slider reports a new value, independent of any round trip through the
  view model.
- **commits-slider-value**: Component MUST write the slider's new value
  into the view model's setting observer whenever the slider reports a new
  value that differs from the setting observer's current value.
- **skips-redundant-commits**: Component MUST NOT write to the view
  model's setting observer when the slider's new value equals the setting
  observer's current value.
- **syncs-on-external-change**: Component MUST re-synchronize the title
  label's text, the slider's value, and the caption label's text — by
  re-reading the view model's title and value — whenever the view model
  reports an external change.
- **overwrites-view-model-onchange**: Component MUST register its own sync
  handler as the view model's external-change handler during
  initialization, replacing whatever handler, if any, was previously
  registered on that view model (see Platform Notes for the mechanism the
  source uses).
- **exposes-constituent-views**: Component MUST expose the title label,
  the slider, and the caption label as public, directly-accessible
  properties.
- **requires-view-model-and-formatter-at-construction**: Component MUST
  require both a view model and a formatter to construct a usable
  instance; no construction path may produce a usable instance without
  both (see Platform Notes for how the source enforces this on
  this platform).
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

