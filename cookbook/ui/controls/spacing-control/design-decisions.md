
- **Decision**: (AppKit) Keep the range's floor and ceiling out of the
  fields' `NumberFormatter` and clamp only inside
  `Spacing.setting(_:in:)`/`Spacing.adjusting(_:by:in:)`.
  **Rationale**: the source comment on `makeField` explains that a
  `NumberFormatter` with a `maximum` refuses out-of-range text outright
  rather than clamping it, and AppKit answers that refusal by declining to
  end editing — trapping the caret in an emptied field. `Spacing` is the
  one place that can clamp instead of reject.
  **Approved**: pending
- **Decision**: (AppKit) Give arrow buttons and steppers
  `refusesFirstResponder = true`, keeping Tab limited to the four or two
  number fields, depending on `style`.
  **Rationale**: the source comments on `makeStepper`/`makeArrowButton` state
  that a stepper or an arrow in the tab loop would put extra stops between
  two number fields — Tab is for the numbers.
  **Approved**: pending
- **Decision**: (AppKit) Intercept Tab explicitly inside
  `control(_:textView:doCommandBy:)` rather than relying on AppKit's
  inferred key-view loop, and only within the control — at either end,
  focus is handed back to whatever `nextKeyView` the panel wired up.
  **Rationale**: the source comment explains that this control's subviews are
  frame-placed, not constraint-placed, so AppKit's inferred loop would
  thread the control's numbers in among whatever else the panel shows; a
  closed ring was considered and rejected as a focus trap.
  **Approved**: pending
- **Decision**: (AppKit) Bound `SpacingHandle.claimsPress`'s wait at
  `patience` (`0.3`s) in addition to the per-event `grace` (`0.12`s).
  **Rationale**: the source comment explains a resting trackpad delivers a
  steady trickle of sub-`slop` jitter events that each restart an unbounded
  `grace` timer, making a held-still arrow's repeat unreachable on a
  trackpad (though reachable on a mouse, which is genuinely silent);
  bounding the total wait fixes the trackpad case without shortening the
  mouse case.
  **Approved**: pending
- **Decision**: Scale the diagram 1:1 with the value, capped at the maximum
  displayed inset (`40pt`), rather than compressing the whole range into a
  smaller diagram.
  **Rationale**: the source comment on `maximumDisplayedInset` explains that an
  arrow standing against the edge it moves travels with that edge; at a
  smaller display scale, a pressed arrow could slide most of its own length
  out from under a held pointer and stop repeating before the range ended.
  The 1:1 cap, paired with freezing a pressed pair's seat
  (freezes-pressed-arrow-pair), is what keeps a full-range hold under the
  pointer.
  **Approved**: pending
- **Decision**: The control performs no contrast check: text, arrow, frame-stroke and pane-stroke colors are the active theme's roles as resolved, with no 4.5:1 text or 3:1 non-text floor enforced.
  **Rationale**: The theme model gives these roles no contrast floor and nothing in the implementation verifies the pairs. Closing the gap means a theme-level contrast audit of the roles against real theme values, or adding a contrast floor to the theme model's primary text, accent and border roles.
  **Approved**: pending

