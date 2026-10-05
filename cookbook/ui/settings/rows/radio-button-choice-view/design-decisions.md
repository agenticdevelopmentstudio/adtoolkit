
- **Decision**: Compose two nested vertical/axis-driven groups (an outer
  vertical group of [label, controls group] plus an inner controls group)
  rather than using the single horizontal [label, spacer, control] row
  layout every other row in this family uses (AppKit/UIKit source: not
  calling `ComposableSettings.makeRow`).
  **Rationale**: a multi-choice radio group needs to grow along its own axis
  independent of the heading, unlike a single trailing control (a switch,
  slider, or popup) that fits beside the label in one row's height; source
  never calls the shared row-composition helper anywhere in this file.
  **Approved**: pending
- **Decision**: Switch the controls group's alignment between leading
  (vertical axis) and first baseline (horizontal axis) via the source's own
  branch, rather than using one alignment for both orientations.
  **Rationale**: stacked buttons of possibly different widths want a common
  left edge when arranged vertically, while buttons placed side by side want
  their title text sitting on one shared line, which first-baseline
  alignment provides and leading alignment does not.
  **Approved**: pending
- **Decision**: Build each choice's control from the platform's stock
  radio-button factory (AppKit/UIKit source: `NSButton(radioButtonWithTitle:)`)
  rather than pairing a bare radio control with a separate themed label per
  choice, the way the heading label is built.
  **Rationale**: this factory is the standard platform mechanism that
  bundles a radio control and its title into one control; source builds no
  second themed label per row, at the traceable cost that per-choice titles
  do not follow the app's theme size-scale or repaint-on-theme-change path
  the way the heading label does (see Appearance).
  **Approved**: pending
- **Decision**: Leave every radio button unselected when the view model's
  value matches no choice's value, rather than falling back to a default
  selection.
  **Rationale**: the sync pass's selected/not-selected comparison is
  evaluated independently per button with no fallback branch in source; the
  component makes no attempt to guarantee "exactly one selected" when the
  view model's value is not representable by any choice.
  **Approved**: pending
- **Decision**: Both the coder-based initializer and the frame-only
  initializer trigger a fatal error (AppKit/UIKit source: `init(coder:)`,
  `init(frame:)`), leaving the view-model-taking initializer as the only
  usable one.
  **Rationale**: The view has no meaningful default state — it cannot
  render a title, choice set, or value without a view model — so both
  inherited initializers that could construct it without one are
  intentionally disabled.
  **Approved**: pending
  Known defect: the frame-only override's fatal-error message is the
  truncated string `"init(frame frameRect: NSRect"` (missing its closing
  parenthesis); it is reproduced here exactly as written in source, not
  corrected.
- **Decision**: The initializer unconditionally assigns the view model's
  change-notification callback, replacing whatever handler (if any) was
  previously registered on that view model instance, rather than composing
  with an existing handler.
  **Rationale**: that callback is a single property; a plain assignment is
  the simplest way to route external changes into the component's sync
  pass, at the traceable cost that another party's previously registered
  callback on the same view-model instance is silently discarded (see Edge
  Cases).
  **Approved**: pending
- **Decision**: Leave the heading label with no accessibility group or
  title-link to the radio buttons beneath it, unlike the sibling checkbox
  row, which does link its single control to its label.
  **Rationale**: Not yet decided; see Accessibility (Label requirements) for
  what the source does and does not implement. The WinUI, Compose, and web
  notes already assume a named accessibility group as the eventual target
  for this component.
  **Approved**: pending
- **Decision**: The component performs no contrast check of its own: the heading label's primary-text color resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
  **Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
  **Approved**: pending

