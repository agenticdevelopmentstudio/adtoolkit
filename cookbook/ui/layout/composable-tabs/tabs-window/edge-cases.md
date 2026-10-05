
- **Null/empty input**: selecting a tab, or setting the active tab, by an id
  that names no group in this window MUST be ignored (MUST) rather than
  clearing the current selection. Listing a tab's panes with an unparsable
  or unknown identifier MUST return an empty array (MUST). An assignment to
  the enabled-edge set MUST NOT trip the last-enabled-edge refusal partway
  through, because enables are applied before disables (MUST) — see
  **edge-set-assignment-order**.
- **Boundary values**: exactly one remaining tab group MUST refuse to close
  (MUST); exactly one remaining enabled edge MUST refuse to disable (MUST).
  These are the only two lower-bound guards in the source; no upper bound on
  tab or edge count exists.
- **Concurrent access**: every mutation (tab add/remove/select, edge
  toggle, persistence) is confined to a single thread, so there is no
  defined behavior for access from another thread — none is needed, since
  this kind of window is inherently single-threaded in its host
  environment. Within that single thread, reentrancy during a single
  operation is guarded explicitly: a reload-in-progress guard suppresses
  side effects while tabs are being reloaded, an arrangement-mirroring
  guard stops the mirror from recursing into itself, and a closing guard
  stops a closing window's own teardown from re-persisting a stale tab set
  (MUST for each guard, as implemented).
- **Error states**: the settings-write path and the tab-persistence call
  are invoked without checking a return value or catching an error
  anywhere in this component; per the source's own comments, the
  settings-write path "swallows its errors." A persistence failure
  therefore produces no user-facing error, no retry, and no logged
  diagnostic — this is what the source does, not an idealized
  error-handling requirement. This is recorded as accepted debt in Design
  Decisions above, not treated as an unresolved gap.
- **Offline/disconnected state**: Not applicable — the window performs no
  network requests; all persistence (window frame, tab layout, drawer
  prefs) is local.

