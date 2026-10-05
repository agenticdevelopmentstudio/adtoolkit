
- **one-row-per-permission-in-order**: The component MUST create exactly
  one row per entry in the permissions list it is constructed with, in
  that list's order, and MUST NOT create a row for any permission not
  present in that list.
- **checker-default**: The component MUST pass the status checker it was
  constructed with to every row it creates and to its own action handling,
  and MUST default to a freshly constructed system-backed checker when the
  caller supplies none.
- **rows-in-full-bleed-vertical-stack**: The component MUST lay out its
  rows in a vertical stack with 8pt spacing and leading alignment, and
  MUST pin that stack's top, leading, trailing, and bottom edges to its own
  corresponding edges with no additional inset.
- **row-width-pinned-to-stack**: Each row's width MUST be constrained equal
  to the stack's width, so every row spans the full width of the panel.
- **layout-built-once**: The component MUST build its row layout exactly
  once, during construction, and MUST NOT add, remove, or rebuild rows
  afterward for the life of the instance.
- **refreshes-serially-in-order**: The component's refresh operation MUST
  re-read status by calling each row's own refresh in the same order the
  rows were created, and MUST await each row's refresh to complete before
  starting the next row's.
- **refresh-aborts-on-cancellation**: Refreshing MUST stop before
  refreshing any further row as soon as its underlying asynchronous work
  is cancelled, leaving any not-yet-reached row's displayed status
  unchanged.
- **activation-observer**: The component MUST begin observing the host
  application's activation event the first time it becomes attached to a
  window, and MUST NOT register that observer a second time on any
  subsequent attach.
- **schedules-refresh-on-window-attach**: Becoming attached to a window
  MUST schedule a refresh of every row.
- **schedules-refresh-on-app-activation**: The host application becoming
  active MUST schedule a refresh of every row.
- **latest-refresh-wins**: Scheduling a refresh MUST cancel any refresh
  already in flight before starting the new one, so that of any two
  refreshes that overlap, only the one scheduled last can apply its
  results to the rows.
- **action-refresh**: A row's action callback MUST first await the shared
  presenter's grant flow for that row's permission and displayed status,
  and MUST schedule (not await) a refresh only after that call returns.
- **cancels-refresh-and-observer-on-deinit**: Tearing down the component
  MUST cancel any in-flight refresh and MUST remove the component's
  activation observer.
- **supports-direct-refresh**: The component MUST expose a public refresh
  operation that awaits a full re-read of every row's status, independent
  of the window-attach and app-activation triggers.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

