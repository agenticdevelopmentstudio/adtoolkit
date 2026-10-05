
- **Null/empty input**: An empty title shows an empty line; a nil or empty subtitle hides its line.
- **Boundary values**: A start time in the future shows zero.
- **Concurrent access**: Main thread only; the ticker delivers on the main thread.
- **Error states**: Not applicable.
- **Offline/disconnected state**: Not applicable.
- **Run-loop slack**: Ticks may land a tenth of the interval late so the system can coalesce wakeups.

