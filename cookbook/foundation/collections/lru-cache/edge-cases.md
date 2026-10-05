
- **Null / empty input**: Any hashable key, including an empty string, is valid; a stored value may itself be an empty value. A read of an absent key returns nothing and changes no order.
- **Boundary values**: Capacity one holds a single entry, and every new key evicts the previous one. Recency is a monotonically increasing counter that wraps rather than traps on overflow.
- **Concurrent access**: One lock guards the table and the counter; a read mutates recency, so even reads take the lock.
- **Error states**: No operation fails except the constructor on a non-positive capacity.
- **Offline / disconnected state**: Not applicable: The cache has no network access.
- **Cancellation**: Not applicable: The cache has no concern of this kind beyond what Behavioral Requirements state.

