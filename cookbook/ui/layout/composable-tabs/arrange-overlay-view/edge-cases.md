
- Null/empty input (MUST): the pane name defaults to an empty string and
  setting it to an empty string is valid — the label simply shows no text;
  nothing in source guards or rejects an empty pane name. The Add, Remove,
  Move, and Done callbacks default to unset and are always invoked
  defensively, so an unset callback is a documented no-op, not an error.
- Boundary values (MUST): the available-directions callback can return the
  empty set (disabling the entire Move button) or all four directions
  (enabling every Move item); the can-add/can-remove callbacks are plain
  booleans with only two possible results, each directly reflected in the
  corresponding button's enabled state on the next refresh. The caller is
  expected to return `false` from can-remove for the last remaining pane and
  to omit a direction from available-directions when the pane is already at
  that edge of the window (e.g. no `Up` for a pane already at the top). The
  caller's responsibility for these boundary decisions is the reason
  **refresh-is-caller-driven** exists: this view has no independent
  knowledge of "last pane" or "top of window" itself, it only renders
  whatever the callbacks currently report.
- Concurrent access: Not applicable — the component confines all reads and
  writes of its state and UI to a single thread; source provides no path
  for two threads to mutate this view simultaneously.
- Error states: Not applicable — every operation in this file (a button tap
  invoking a callback, refreshing availability rebuilding menu items, a
  theme change repainting colors) is synchronous and non-throwing; no
  network, database, or file-system call exists anywhere in this file that
  could fail.
- Offline/disconnected: Not applicable — this is a purely local UI overlay
  with no networking call anywhere in source.
- Stale availability between refreshes (MUST): Per
  **refresh-is-caller-driven**, if the data behind the can-add, can-remove,
  or available-directions callbacks changes without a subsequent refresh,
  the affected control(s) MUST continue to show their previously computed
  enabled state; this view performs no polling or tree observation of its
  own; that responsibility belongs to the caller.

