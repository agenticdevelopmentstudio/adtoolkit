
- **Null / empty input**: An empty settings list is valid and still pushes the snapshot at start; an empty backoff list attempts nothing and logs the exhausted-retry error immediately.
- **Boundary values**: The default backoff list has three entries, the first being zero, so the first attempt is immediate; a backoff of zero skips the wait but still honors cancellation.
- **Concurrent access**: The push state is confined to the main UI context; the send closure is run off it and receives its body by value.
- **Error states**: A failed send is retried up to the backoff count and then logged and dropped; the receiver keeps its prior state until the next change or reconnect. A snapshot that cannot be built is logged and skipped.
- **Offline / disconnected state**: A failing sender models an unreachable receiver; the retry is bounded and the reconnect handler re-pushes when the receiver returns.
- **Cancellation**: Stopping or starting a newer push cancels the retrying one; cancellation is checked after each wait and before each attempt.

