
- Null/empty input (MUST): Querying an edge's tabs MUST return an empty list
  for an edge with no tabs, never trap. Querying the selected tab or its id
  MUST return none when the active tab (if any) is not a member of the given
  edge. With both the main content and the active tab absent, the shared
  content area MUST be left with no mounted content at all rather than
  showing a blank placeholder.
- Boundary values (MUST): Inserting a tab's index clamp and moving a tab's
  index clamp MUST both handle an index below `0` or past the end of the
  list the same way as one already in range — neither traps nor silently
  ignores the call.
- Concurrent access: Not applicable — the view, its per-edge tab storage,
  and its tab bars are all confined to a single thread; every mutating
  entry point (adding, removing, moving, or selecting a tab, toggling an
  edge, and the internal sync/activation logic) runs on that same thread, so
  this concept provides no path for two threads to mutate one instance at
  the same time.
- Error states (MUST): Looking up the edge for an unknown tab id returning
  none MUST make removing, renaming, or replacing a tab's item silent
  no-ops rather than trap. Selecting a tab MUST be silently ignored when the
  id is not a member of the given edge's own list — it does not search other
  edges for it. The delegate reference is held weakly; a deallocated
  delegate MUST make every delegate notification a no-op without preventing
  the underlying tab mutation from completing.
- Offline/disconnected: Not applicable — this component performs no
  networking of any kind; it manages an in-memory set of tab bars and
  mounts caller-supplied content.
- Reusing one content instance across two tabs: unguarded caller
  precondition. Nothing in adding or inserting a tab refuses or dedupes a
  tab whose content is already parented elsewhere or already mounted as
  another tab's content; callers MUST supply distinct content per tab, and
  the platform's own content-containment mechanism is the only thing that
  reacts to a violation.

