
- **Null/empty input**: No current panel title MUST result in the
  panel-title item showing the empty string, not a placeholder (MUST, see
  **shows-current-panel-title**). With no selection on the navigation control, the control MUST NOT trigger navigate-back or navigate-forward (MUST, see
  **routes-segment-selection-to-navigation**). A request for the sidebar
  tracking separator when the hosted split view does not exist MUST return
  nothing rather than a partially-configured item (MUST, see
  **builds-tracking-separator-from-splitview**).
- **Boundary values**: Not applicable — this file has no numeric,
  countable, or ranged input of its own (two fixed navigation directions and
  one fixed, five-item header-bar list); it defines no minimum/maximum to
  test against.
- **Concurrent access**: All mutation is confined to a single designated
  thread (this file and its base window-lifecycle type are both isolated to
  it), so there is no defined behavior for access from another thread, and
  none is needed for a window controller of this kind. Unlike some sibling
  window controllers in this codebase, this file installs no explicit
  reentrancy guard (no in-flight-operation flag) — none is needed because
  every entry point here (showing the window, the header-bar item factory,
  and the two control actions) runs to completion synchronously before the
  platform can call back in.
- **Error states**: This file performs no fallible operation of its own — no
  network call, no throwing construction, no unchecked access outside the
  safely-guarded accesses already covered by the requirements above. It
  therefore produces no error state to communicate to the user; this is
  what the source does, not an idealized claim of error handling that isn't
  there.
- **Offline/disconnected state**: Not applicable — this file makes no
  network requests.

