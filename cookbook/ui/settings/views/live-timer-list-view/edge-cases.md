
- **Null/empty input**: No timers shows only the empty message.
- **Boundary values**: Reordering timers rebuilds rows but keeps each by id.
- **Concurrent access**: Main thread only.
- **Error states**: Not applicable.
- **Offline/disconnected state**: Not applicable.
- **Window covered or on another Space**: The window stays open but is not seen; the list stops ticking until it is visible again.

