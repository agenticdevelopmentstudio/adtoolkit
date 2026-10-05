
- Null/empty input: Looking up the active node id for a window MUST return
  none rather than trapping or treating a missing window as any particular
  window's state.
- Null/empty input: An event with no associated window MUST be ignored when
  recording events (see **an-event-with-no-window-is-ignored**).
- Null/empty input: A window whose content view is unset MUST be treated as
  having no pane under any point (see **a-nil-content-view-means-no-pane**).
- Boundary values: A window with zero panes MUST have no entry in the active
  id map, and any view queried against that window (there being no pane to
  contain it) counts as active per **view-outside-any-pane-counts-as-active**.
- Boundary values: A window with exactly one pane MUST have that pane hold
  the active id once it appears, per **arrival-claims-active-in-an-unclaimed-window**,
  and MUST have no active pane left once it departs, per
  **departure-clears-active-id-when-no-pane-survives**.
- Concurrent access: The whole component is confined to a single thread;
  every mutation of its window/pane bookkeeping happens there, so concurrent
  access from multiple threads is not a case this file has to handle. Two
  sources that could otherwise race with an in-progress pointer-tracking
  gesture — a window closing, and a highlight-setting change — are explicitly
  re-dispatched onto the main work queue (not a mechanism that pauses during
  the gesture) so a change made while the platform tracks a pointer-down
  gesture is still applied, rather than being deferred until the gesture
  ends.
- Error states: The only "failure" outcome in this file is a view refusing
  input-focus status. This MUST be handled internally by taking focus's
  three-way outcome (taken / nowhere-to-put / refused) as described above; it
  is never surfaced to a caller, logged, or shown to the user — there is no
  user-visible error state for a focus refusal beyond the outline and
  keyboard simply not moving.
- Offline/disconnected: Not applicable. The component makes no network call
  and has no server-backed state; it is a pure in-memory, single-process
  tracker of per-window UI state.

