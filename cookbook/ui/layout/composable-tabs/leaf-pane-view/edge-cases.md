
- **Null/empty input**: The project a pane depends on may become
  unavailable before the view loads — content resolution returns no
  content rather than crashing (MUST, see `content-nil-without-project`).
  `layoutOverride` unset — content and the pane's display name fall back
  to the project's own layout, and the display name falls back further to
  a placeholder-only layout if the project is also gone. Computed Add
  choices empty — requesting Add refuses rather than presenting an empty
  picker (MUST, see `add-refused-when-empty`).
- **Boundary values**: A pane index left unset is the common case; an
  assigned index changes the accessibility identifier's shape (MUST, see
  `accessibility-id-includes-pane-index`). A tab with exactly one pane
  makes the enclosing split refuse removal of that pane. A pane at the top
  of a column has no Up direction available, so the corresponding
  gear-menu and overlay controls are disabled rather than absent.
- **Concurrent access**: This component confines all reads and writes of
  its mutable state (the pane index, the installed overlay, its
  subscriptions, its key-event interception, and the state-owner
  identifier) to a single thread, so there is no concurrent-access hazard
  by construction. The one boundary crossing is the key-event
  interception's own callback, which the platform may invoke off that
  thread; the source re-enters the component's thread to run its
  key-handling logic and only a plain boolean crosses back out, since the
  underlying key-event value itself is not safe to pass between threads.
- **Error states**: When the enclosing split refuses a move, reports Add
  has no legal choices, or reports Remove is not currently legal, the only
  surfaced error is a refusal announcement (default: a system beep) —
  there is no inline error message, banner, or thrown error anywhere in
  this file for these cases, and the recipe describes that as-is rather
  than as an idealized richer error UI.
- **Offline or disconnected state**: Not applicable. This component makes
  no network requests; its only persistence (pane chrome state, through
  the shared pane state store) goes into the project's local database, and
  nothing in this file or its immediate collaborators references a network
  resource.

