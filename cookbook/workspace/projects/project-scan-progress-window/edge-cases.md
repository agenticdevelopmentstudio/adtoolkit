
- **Null and empty input**: Not applicable — none of construction,
  presenting, or finishing accept any parameter, so there is no null or
  empty input to handle.
- **Boundary values**: The progress indicator's range is fixed at 0 to 1,
  and the close delay is fixed at 1.0 second; none of these are
  caller-supplied, so there is no boundary condition a caller can vary.
  MUST (this is the component's actual, unparameterized behavior).
- **Concurrent access**: all access to the headline, progress indicator,
  and window state is confined to the UI's main execution context (see
  `confines-to-ui-thread`). Calling finish a second time before the first
  call's scheduled close fires MUST queue a second delayed close that also
  closes the panel; the second call lands on an already-closing or
  already-closed window, which is a harmless no-op. MUST.
- **Error states**: the only defensive check is present's guard against a
  missing window; it MUST return silently, with no error signal of any
  kind, since nothing here throws or returns an error value. MUST.
- **Offline or disconnected state**: Not applicable — nothing here makes a
  network call; its only work is updating local UI state and scheduling one
  local timer.
- **Cancellation**: the component provides no cancel operation of any
  kind; it is deliberately not modal and deliberately not cancellable. This
  is the component's actual behavior, not an unresolved gap.
- **Out-of-order calls**: finishing MUST behave identically whether or not
  presenting was called first — it updates the indicator and headline and
  schedules the close unconditionally; a panel that was never shown is
  simply closed once, while still hidden. MUST.

