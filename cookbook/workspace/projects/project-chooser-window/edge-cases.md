
- **Null and empty input**: A coordinating component whose repository list
  is empty at construction leaves the browser's selection absent, so the
  Open button MUST stay disabled through view loading (see
  **open-button-enablement-tracks-selection**); Cancel MUST remain fully
  functional regardless (see **cancel-button-forwards-nil**). Running the
  modal session MUST resolve to no repository if the window were ever
  absent, but in practice construction always produces a concrete window
  and no other construction path exists, so this is a defensive check on a
  case the dialog's own contract never actually produces.
- **Boundary values**: The window's minimum size fixes the one numeric
  boundary this file defines: the window MUST NOT be resized below 360×300
  even though it opens at 460×480 (see **window-identity-fixed-at-init**).
  The number of projects in the coordinating component's repository list —
  zero, one, or many — imposes no boundary of its own on this file; scale
  limits on the project list belong to the project browser, not to this
  window.
- **Concurrent access**: Every mutation of the chosen value and every
  access to the content view, browser, or Open button is confined to a
  single execution context (see Platform Notes), so no interleaving on this
  file's own state can be observed torn. Neither the choose-and-callback
  entry point nor the menu command that calls it guards against being
  invoked a second time before the first session ends — unlike the project
  scan operation's own busy-guard — so two rapid invocations (for example,
  an "Open Project…" command fired twice before the first window paints)
  construct two independent chooser windows and stack two nested modal
  sessions; the platform resolves this deterministically (last-opened is
  topmost and must be dismissed before the previous session resumes — see
  **window-close-ignored-when-not-active-modal-session**), but the two
  windows and their buttons carry identical, non-instance-scoped
  accessibility identifiers (see **accessibility-identifiers-fixed**), so
  automation driven by those identifiers alone cannot distinguish the two
  simultaneously open chooser windows.
- **Error states**: This dialog makes no call that can throw and defines
  no error type of its own; it reads the coordinating component's
  repository list only indirectly, through the project browser it hosts,
  and that list is a non-throwing, already-materialized collection — any
  failure in producing it (a scan error, a database read error) happens
  upstream, entirely out of this file's view.
- **Offline or disconnected state**: Not applicable — this file makes no
  network request. It only reads local, in-memory state (the coordinating
  component's repository list) through the browser it hosts and has no
  notion of connectivity of its own.

