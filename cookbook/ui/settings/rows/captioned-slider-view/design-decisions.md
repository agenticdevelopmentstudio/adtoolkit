
- **Decision**: (AppKit) Update the caption label from the slider's raw
  `newValue` inside `sliderChanged(_:)`, ahead of writing to
  `viewModel.settingObserver.value`, rather than waiting for `sync()` to
  run off the round-tripped `viewModel.value`.
  **Rationale**: This gives the caption an immediate, per-tick update
  while dragging instead of a value that lags one `onChange` cycle behind
  the slider's own position.
  **Approved**: pending
- **Decision**: (AppKit) Set the slider's horizontal content-hugging
  priority to `1` and the caption label's horizontal
  compression-resistance priority to `.required`.
  **Rationale**: The source comment states this priority is "below the
  row spacer's `defaultLow` so the slider, not the gap, takes the width
  left over after the label and caption" — this makes the slider, rather
  than inter-item spacing or the caption, absorb any extra row width,
  while guaranteeing the caption is never truncated.
  **Approved**: pending
- **Decision**: Guard the setting observer's value assignment with an
  equality check before writing.
  **Rationale**: Avoids redundant writes to the observer (and any
  observer-driven feedback loop) when the slider reports a value that
  hasn't actually changed.
  **Approved**: pending
- **Decision**: (AppKit) Force a fatal error from both `init(coder:)` and
  the frame-only `init(frame:)`, leaving `init(viewModel:formatter:)` as
  the only usable initializer.
  **Rationale**: The view has no meaningful default state — it cannot
  render a title, range, or caption without a view model and a
  formatter — so both inherited `NSView` initializers that could
  construct it without those are intentionally disabled rather than left
  to produce a half-configured row.
  **Approved**: pending
- **Decision**: Overwrite the view model's external-change handler
  unconditionally at construction, rather than composing with or
  preserving any handler already registered on that view model.
  **Rationale**: The source's external-change property is a single
  closure/callback slot; giving the row exclusive ownership of it avoids
  ambiguity about ordering multiple observers, at the cost of silently
  dropping any handler registered before construction (see
  **overwrites-view-model-onchange**).
  **Approved**: pending
- **Decision**: Assign the view model's minimum/maximum straight to the
  slider's minimum/maximum with no minimum-less-than-maximum check.
  **Rationale**: Bounds validation is the view model's responsibility, if
  anywhere; adding a second check in the view would duplicate that
  concern and could silently mask a caller bug instead of surfacing it
  (see **does-not-validate-range**).
  **Approved**: pending

