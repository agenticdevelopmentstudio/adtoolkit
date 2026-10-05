
- **Null / empty input**: Absent and empty text always yield the caller's default for all three readers.
- **Boundary values**: A value equal to either bound of the range is returned as is; a negative integer is parsed and clamped like any other.
- **Concurrent access**: The functions are stateless and safe to call from any thread.
- **Error states**: No function fails; malformed text becomes the default.
- **Offline / disconnected state**: Not applicable: The reader has no network access.
- **Cancellation**: Not applicable: The reader has no concern of this kind beyond what Behavioral Requirements state.

