
- **Null / empty input**: Any hashable key, including an empty string, is accepted; a compute that returns an empty value is cached like any other.
- **Boundary values**: A time-to-live of zero or less makes every entry stale on the next lookup, so every call computes; a capacity of one holds a single entry and each new key replaces it. Freshness is strict: age equal to the time-to-live is stale.
- **Concurrent access**: All reads and writes of the table are serialized by one lock; the compute runs outside it, so concurrent misses for one key duplicate work rather than block. Callers that must be single-flight already are.
- **Error states**: A failing compute propagates and leaves the table unchanged (`failed-compute-caches-nothing`). The only programmer error is a non-positive capacity.
- **Offline / disconnected state**: Not applicable: The memo has no network access.
- **Cancellation**: Not applicable: The memo has no concern of this kind beyond what Behavioral Requirements state.

