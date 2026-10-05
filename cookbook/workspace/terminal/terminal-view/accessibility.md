
- **Role**: Not set by this view — no accessibility role/trait assignment
  appears in source; whatever role the underlying terminal engine
  establishes is inherited unmodified.
- **Label**: Not set by this view — no accessibility label assignment
  appears in source; labeling is entirely the underlying terminal
  engine's own responsibility.
- **Announce state changes**: Not applicable: this view defines no
  disabled or loading state of its own to announce (see States).
- **Keyboard navigation**: Not set by this view — no key-handling
  override appears in source; keyboard input and focus traversal are
  entirely the underlying terminal engine's own, inherited unmodified.
- **Minimum tap target**: Not applicable — this view defines no
  tap/click target of its own; it inherits the underlying terminal
  engine's full-bounds hit area unmodified and sets no separate frame or
  size constraint.
- **contrast-ratio**: the caret color and text color are caller-supplied values applied verbatim (see **filled-caret-color**, **hollow-text-color**); the view performs no contrast computation of its own (see Design Decisions).

