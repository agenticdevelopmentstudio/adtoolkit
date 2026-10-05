
- **Null / empty input**: A missing or empty raw kind yields the legacy bare account key (`key-from-raw-value`); an empty item key parses to nothing.
- **Boundary values**: An item key whose first colon is its first character has an empty prefix that matches no kind and parses to nothing; a key ending in a colon parses to a known kind with an empty name.
- **Concurrent access**: The type holds no state, so any number of callers may build and parse keys at once.
- **Error states**: Parsing never fails with an error; an unrecognized key returns nothing and the caller treats it as a legacy or foreign key.
- **Offline / disconnected state**: Not applicable: The kind type has no network access.
- **Cancellation**: Not applicable: The kind type has no concern of this kind beyond what Behavioral Requirements state.

