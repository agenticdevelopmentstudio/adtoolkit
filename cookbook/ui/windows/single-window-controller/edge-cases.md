
- **Empty window ID**: the window registry's registration operation silently
  skips registration when the window ID is empty; the controller still
  builds and shows a window, it simply cannot be looked up by ID afterward.
  This is a deliberate no-op guard in the registry, not an error path.
- **Duplicate window ID across two live controllers**: the window registry's
  own documentation states its "one live controller per ID" assumption;
  registering a second controller under an ID already in use replaces the
  prior registry entry, so a lookup by that ID returns only the most
  recently registered instance. The prior controller's window is unaffected
  by the replacement — the registry simply stops tracking it.
- **The fit-to-content operation called with a zero or negative dimension**:
  the fit-to-content operation guards against a non-positive width or
  height by returning immediately without applying any frame change; a
  degenerate size therefore never reaches the content-hugging frame
  calculation or the platform's own minimum-size clamping (a minimum size is
  only ever threaded into a fit that actually runs).
- **Concurrent access from multiple threads**: Not applicable — the whole
  class is confined to a single designated thread, so the compiler prevents
  concurrent access from another thread; there is no runtime race to defend
  against.
- **Error/failure states**: Not applicable — none of this class's APIs are
  throwing or failable; window construction itself cannot fail with the
  parameters used here, so there is no error path to define.
- **Offline/disconnected state**: Not applicable — this class has no network
  dependency.
- **Unbounded settle-wait while the mouse button is held**: the debounced
  refit (see **move-refit-debounce**, **refit-drag-deferral**) reschedules
  itself indefinitely as long as a mouse button is held, with no maximum
  retry count; a pathologically long drag defers the refit for the duration
  of the drag rather than firing early with a stale frame. This is a
  deliberate tradeoff (see Design Decisions), not an unhandled failure.
- **The configuration hook mutates the delegate or frame**: Because the hook
  runs before delegate assignment and frame restoration (see
  **build-sequence**), any delegate-firing change the configuration hook
  makes (e.g. resizing the window) is observed by the resize callback like
  any other resize, including its frame-persistence save path.

