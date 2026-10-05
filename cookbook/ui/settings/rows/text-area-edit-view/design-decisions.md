
- **Decision**: Document caret-position-on-external-change's use of the
  value's grapheme-cluster count as a text-position location measured in a
  finer-grained unit (AppKit: a UTF-16 offset via `NSRange`) as a known
  precision quirk rather than idealizing it into "moves the caret to the
  exact end."
  **Rationale**: for text containing graphemes that span more than one such
  unit (emoji, some combining sequences, many CJK-extension characters),
  grapheme count is strictly less than that finer-grained length, so the
  computed position lands short of the true end. It never exceeds the
  string's bounds (grapheme count is never greater than the finer-grained
  length), so this is reduced caret precision for such text, not a crash —
  technical debt affecting behavioral correctness, recorded per
  source-fidelity rather than smoothed over. (AppKit source.)
  **Approved**: pending
- **Decision**: Treat the closure-overwrite behavior of the view model's
  change notification as a known limitation rather than contract behavior
  other code should rely on.
  **Rationale**: the change notification is a single callback property;
  construction unconditionally assigns its own handler to it, which
  silently drops whatever handler, if any, was previously registered on the
  same view model instance. That is a source-traceable hazard of plain
  single-callback assignment, not a deliberate feature — recording it as a
  design decision keeps it from being read as required behavior for other
  implementations to replicate, while acknowledging the source does behave
  this way today.
  **Approved**: pending
- **Decision**: Keep the label-resync (setting the label's text to the view
  model's title) inside the change-notification handler even though the
  view model's title cannot change after construction for this view model.
  **Rationale**: the title is immutable after construction, so for this
  component today the assignment is always a no-op. It exists because the
  same handler is also responsible for the value-sync and caret logic
  (external-value-adoption, caret-position-on-external-change) that must run
  regardless, and keeping the label resync alongside them means every
  settings row's change handler is written the same shape, so a reviewer or
  future editor of any row type does not have to remember which ones need
  it — a present-day consistency benefit, not a hedge against a hypothetical
  future view model.
  **Approved**: pending
- **Decision**: Accept the scroll view's height formula's `+ 8` constant
  (AppKit) as an undocumented magic number in source, while noting the most
  plausible explanation rather than asserting it as fact.
  **Rationale**: the AppKit source never comments why `8` specifically is
  added to `(lineHeight * visibleLines).rounded()`; the value matches the
  sum of the text container inset's 4pt top and 4pt bottom insets set a few
  lines earlier in the same initializer, which would make the `+ 8`
  compensation for that inset so all `visibleLines` lines remain fully
  visible — but source does not state this correlation explicitly, so it is
  recorded here as the most likely reading, not as verified fact.
  **Approved**: pending
- **Decision**: Restrict superview-width-claim's constraint to priority
  `.required - 1` (999, AppKit) rather than `.required` (1000).
  **Rationale**: per the source's own comment, the enclosing stack already
  aligns leading, so the component must claim the full width itself to be
  usable for editing — but a host that insets its hosted controls (the
  comment's example: a popover pinning `width == stack.width - 32`) would
  otherwise create two conflicting required-width constraints, which
  AppKit resolves by breaking whichever one it prefers. One priority level
  below required avoids that conflict while still winning against any
  lower-priority sizing.
  **Approved**: pending
- **Decision**: Reuse the Text Edit View's label-construction helper for the
  label rather than composing the label independently or subclassing the
  Text Edit View (AppKit: `TextEditView.createLabel(title:)`).
  **Rationale**: this component needs the Text Edit View's label
  construction (the shared row-label helper, button text role) but none of
  its row layout, single-line field, or Return-commit path, which are wrong
  for a multi-line, commit-on-focus-loss editor; calling the one static
  helper it needs avoids inheriting behavior that does not apply.
  **Approved**: pending
- **Decision**: The component performs no contrast check of its own: the label's and editor's primary-text color against the control-background color resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
  **Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
  **Approved**: pending

