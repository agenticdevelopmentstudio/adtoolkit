
- **Null/empty input**: All fields default to empty and empty is valid.
- **Boundary values**: No length limits are applied.
- **Concurrent access**: Main thread only.
- **Error states**: A refused save is handled by reverting, which restores stored values.
- **Offline/disconnected state**: Not applicable.
- **Loading a different record while editing**: The caller MUST end editing first, or the pending edit lands in the new record.

