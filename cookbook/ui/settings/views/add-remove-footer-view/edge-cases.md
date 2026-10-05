
- **Null/empty input**: An empty prefix produces identifiers that start with a dot; callers SHOULD pass a real prefix or none.
- **Boundary values**: Many accessories simply extend the bar; the footer defines no wrapping.
- **Concurrent access**: Main thread only.
- **Error states**: A press with no callback assigned does nothing.
- **Offline/disconnected state**: Not applicable.

