
- **Null/empty input**: An empty or whitespace-only error message is trimmed to empty and still reported.
- **Boundary values**: Not applicable: no numeric limits are defined.
- **Concurrent access**: Not applicable: all helpers are for use on the main thread.
- **Error states**: With no window every helper takes its safe path: confirmations decline, folder choice reports nothing, reports are logged.
- **Offline/disconnected state**: Not applicable: the component performs no networking.

