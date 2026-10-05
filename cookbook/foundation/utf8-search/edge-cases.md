
- **Null / empty input**: Empty needle is always found; empty string never contains a non-empty needle.
- **Boundary values**: A needle longer than the string is not found; a needle equal to the whole string is found. The search is not aware of grapheme boundaries, so a needle that is a bare combining mark matches inside a longer character.
- **Concurrent access**: The search reads an immutable value copy and shares no state.
- **Error states**: It cannot fail.
- **Offline / disconnected state**: Not applicable: The search helper has no network access.
- **Cancellation**: Not applicable: The search helper has no concern of this kind beyond what Behavioral Requirements state.

