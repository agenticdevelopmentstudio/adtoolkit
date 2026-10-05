
- **Null and empty input**: No open project windows leaves the window,
  tab, and pane enumerations all empty, and every id-based lookup returns
  no result (MUST; the enumerations and lookups are plain walks over the
  open windows, which is itself empty when nothing is open). A `uniqueID`
  argument that is the empty string or any other non-matching string is
  handled by the same string-equality comparison as any other miss — it
  MUST return no result, never throw (MUST, see
  **window-lookup-miss-returns-nil**, **tab-lookup-miss-returns-nil**,
  **pane-lookup-miss-returns-nil**).
- **Boundary values**: A tab group MAY be drawn on zero edges
  (**tab-edges-may-be-empty**) after every edge is disabled, in which case
  the pane enumeration for that tab group's window contributes zero panes
  for that tab while the tab enumeration still lists the tab itself
  (MUST). There is no maximum enforced on the number of open windows, tabs
  per window, or panes per tab — enumeration is a linear walk with no
  capacity limit.
- **Concurrent access**: Every operation in this surface, and on all three
  wrapper types, is confined to the UI's main execution context (MUST, see
  **main-thread-confinement**); the AppleScript scripting layer itself dispatches command
  handlers on the main thread (see
  `adtoolkit://cookbook/system/scripting`), so no two enumerations or
  lookups from this surface can interleave with each other or with a
  window opening or closing. There is no lock, queue, or independent
  concurrency state defined here — main-thread confinement is the entire
  concurrency story.
- **Error states**: This surface defines no throwing operation and
  surfaces no error type of its own. A branch that cannot be resolved — no
  project controller for the window, no branch controller for the
  directory, or a detached-HEAD checkout — is not an error condition here;
  it is folded to the empty string before it would ever reach a caller
  (MUST, see **tab-branch-empty-when-unresolved**). Any error a git
  subprocess could raise is fully absorbed inside the branch controller's
  own refresh operation before its current branch is ever read by this
  surface (see `adtoolkit://cookbook/workspace/projects/branch-controller`);
  none of it is observable through the scriptable tab's `branch`.
- **Offline or disconnected state**: Not applicable in the network sense —
  nothing here makes a network call. Git itself is local-only, and even
  that local subprocess call happens one layer below this surface, inside
  the branch controller; this surface only reads an already-resolved
  current-branch snapshot.
- **A pane, tab or window that has closed between enumeration and use**: A
  scriptable window's underlying window MAY become unavailable between
  when a script is handed the wrapper and when it reads a property from
  it, because a script "can keep a reference to a window it then closes";
  every property degrades to its documented fallback rather than crashing
  (MUST, see **window-degrades-when-controller-is-gone**). The scriptable
  pane's `isInWindow` exists specifically because a close request's effect
  can be silently declined by the host, so "the request was delivered"
  and "the pane is gone" are answered by two different questions (MUST,
  see **pane-is-in-window-reasks-live-membership**).

