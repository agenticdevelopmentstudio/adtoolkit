
- **Decision**: Re-apply the slider's minimum and maximum (in addition to the
  label text and the slider's value) inside the external-change handler,
  not just at initialization — unlike the sibling captioned slider row
  (adtoolkit://cookbook/ui/settings/rows/captioned-slider-view),
  whose sync leaves the slider's range untouched after construction.
  **Rationale**: Lets a caller mutate the view model's range after the row is
  built and have the slider reflect the new bounds without recreating the
  view.
  **Approved**: pending
- **Decision**: Give the slider a low horizontal content-hugging priority
  (AppKit/UIKit source: set to `1`).
  **Rationale**: The source comment states this priority is set below the
  row spacer's own low default priority so the slider, not the gap,
  takes the width left over after the label — this makes the slider,
  rather than inter-item spacing, absorb any extra row width.
  **Approved**: pending
- **Decision**: Guard the view model's value assignment with an equality
  check before writing.
  **Rationale**: Avoids redundant writes to the view model (and any
  observer-driven feedback loop) when the slider reports a value that
  hasn't actually changed.
  **Approved**: pending
- **Decision**: Force a fatal error from both the coder-based and the
  frame-only initializers (AppKit/UIKit source: `init(coder:)`, the
  frame-only `init(frame:)`), leaving the view-model-taking initializer
  as the only usable one.
  **Rationale**: The view has no meaningful default state — it cannot render
  a title or range without a view model — so both inherited initializers
  that could construct it without one are intentionally disabled rather
  than left to produce a half-configured row.
  **Approved**: pending
- **Decision**: Assign the component's change-notification handler
  unconditionally at construction, without preserving or chaining any
  handler already registered on the same view-model instance —
  constructing a second instance of this component (or any other
  observer) against the same view model silently drops the earlier
  handler.
  **Rationale**: This component owns its view model's re-sync handler for the
  view's lifetime; supporting more than one simultaneous observer on a
  single view model would need a multicast mechanism the source does not
  implement, so one view per view model is the stated limit rather than
  an unstated side effect.
  **Approved**: pending
- **Decision**: The component performs no contrast check of its own: the label's primary-text color resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
  **Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
  **Approved**: pending

