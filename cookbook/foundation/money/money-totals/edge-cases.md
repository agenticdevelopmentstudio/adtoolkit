
- **Null / empty input**: An empty totals value is empty, has no currencies and an empty description.
- **Boundary values**: A bucket can hold a negative or zero figure and still appears, because only the act of adding creates it; adding zero hundredths creates a zero bucket.
- **Concurrent access**: It is a mutable value type with no lock; each owner mutates its own copy.
- **Error states**: No operation fails; integer addition at extreme magnitudes overflows, which traps in Swift; the type adds no guard.
- **Offline / disconnected state**: Not applicable: The totals type has no network access.
- **Cancellation**: Not applicable: The totals type has no concern of this kind beyond what Behavioral Requirements state.

