
- **Null/empty input**: the base's content property reassigned to absent
  after construction (it is a settable, inherited property) — the typed
  accessor returns absent rather than crashing, per
  **returns-nil-for-non-matching-content-view-controller**. MUST.
- **Boundary values**: Not applicable — the caller-supplied content-controller
  type and view type are reference-type generic constraints, not measured or
  bounded inputs.
- **Concurrent access**: The window controller is confined to a single
  designated thread by inheritance from the single-instance window base's own
  thread confinement. The content wrapper declares no explicit thread
  confinement of its own, but the platform's content-controller base is
  itself confined to that same thread in the platform overlay, so the wrapper
  inherits that confinement the same way. Neither type adds an additional
  concurrency guard of its own.
- **Error states**: Not applicable beyond the deliberate fatal error in
  archive-based construction — no throwing or failable operation exists in
  the component.
- **Offline/disconnected state**: Not applicable — the component has no
  network dependency.

