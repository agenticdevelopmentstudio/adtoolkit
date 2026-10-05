
- **Null/empty input**: Showing the panel guards against the underlying
  window not existing and returns without effect if so
  (**guards-show-against-missing-window**) — in practice the window always
  exists once construction has run, but the guard is present. If no screen
  contains the pointer location and there is no main screen either,
  positioning falls back to centering rather than computing an invalid
  origin (**falls-back-to-centering-without-visible-frame**).
- **Boundary values**: The top-edge offset is a fixed 20% fraction, not a
  configurable input, so there is no boundary range to exercise on it
  directly.
- **position-clamping**: Positioning MUST compute the panel's origin from the window's own size and the resolved screen's visible area alone, and MUST NOT clamp it against either edge. If the content rect's height exceeds the visible area's height reduced by the top-edge offset fraction, the computed vertical origin goes negative and the panel renders partly below the visible area, or off it entirely on a very short screen.
- **Concurrent access**: The controller is confined to a single thread of
  execution for its entire lifetime, so there is no defined behavior for
  access from another thread — none is needed because this kind of window
  controller is inherently single-threaded. See Platform Notes for how that confinement is enforced. Within that single
  thread, the one reentrancy case the source guards against is closing
  being re-entered while a dismissal is already unwinding (`isDismissing`),
  covered by `guards-close-against-reentrancy` and
  `ignores-focus-loss-while-already-dismissing` above (MUST).
- **Error states**: No fallible operation exists in this file — window and
  panel construction, positioning, and dismissal have no return code or
  thrown error to handle, so there is nothing for this file to report or
  recover from.
- **Offline/disconnected state**: Not applicable — the controller performs
  no network requests and has no dependency on connectivity.

