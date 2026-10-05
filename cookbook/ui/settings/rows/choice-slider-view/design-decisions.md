
- **Decision**: Fix the value label's width to a single constant, computed
  once at init from the widest choice label rendered in the label's own
  font, rather than letting the label's intrinsic width vary per choice.
  **Rationale**: Per the source's own comment, this keeps "the slider's
  width from oscillating as the user drags through shorter/longer choice
  labels (e.g. \"Small\" → \"Extra Small\")."
  **Approved**: pending
- **Decision**: (AppKit) Force the title label's and value label's
  horizontal content-hugging priority to `.required` and the slider's to
  `1`, rather than leaving the flanking labels at AppKit's default hugging
  priority.
  **Rationale**: Per the source's own comment, below the row spacer's own
  `defaultLow` priority "the two tie and the free width is split between
  them" — forcing `.required` on the flanking labels guarantees the slider
  alone absorbs the row's extra width.
  **Approved**: pending
- **Decision**: Update the value label's text only through the
  selection-sync logic, called from the view model's external-change
  notification, rather than writing it directly inside the slider's action
  handler.
  **Rationale**: Unlike a sibling row that accepts a caller-supplied
  formatter and updates its caption optimistically inside its own slider
  handler, this component's value text always comes from re-searching the
  view model's choices for the matching entry — the component performs
  that lookup in exactly one place (the selection-sync logic) rather than
  duplicating it inside the action handler, at the cost of the one-turn
  display lag documented in Edge Cases.
  **Approved**: pending
- **Decision**: Leave the slider's position and the value label's text
  untouched when the view model's value matches no choice's value, rather
  than falling back to a default index or clearing either label.
  **Rationale**: The selection-sync logic's index-match guard has no
  fallback branch in source; the component makes no attempt to represent
  an unrepresentable value, leaving whatever the elements last displayed.
  **Approved**: pending
- **Decision**: (WinUI) Measure the value column's width once, in
  code-behind after `Loaded`, from the longest label string, rather than
  re-measuring it if the control's `FontSize` or the active theme changes
  later.
  **Rationale**: Mirrors the source's own one-time `ceil(longestLabelWidth)`
  computation (see fixes-value-label-width); this recipe does not introduce
  WinUI-specific staleness handling beyond matching that choice.
  **Approved**: pending
- **Decision**: (AppKit) Both `init(coder:)` and the frame-only
  `init(frame:)` trigger a fatal error, leaving `init(viewModel:)` as the
  only usable initializer.
  **Rationale**: The view has no meaningful default state — it cannot
  render a title, tick range, or value without a view model — so both
  inherited `NSView` initializers that could construct it without one are
  intentionally disabled. (The frame-only override's fatal-error message
  text is a separate, unrelated observation — see Platform Notes.)
  **Approved**: pending

