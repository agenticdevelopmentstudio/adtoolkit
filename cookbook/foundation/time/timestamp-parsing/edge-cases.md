
- **Null / empty input**: Empty text returns nothing; whitespace-only text matches no shape and returns nothing.
- **Boundary values**: A SQLite timestamp with fractional seconds does not match the SQLite shape here; the UTC timestamp spec adds a fast path for the millisecond form. A date without a time matches none of the shapes.
- **Concurrent access**: The shared formatters are configured once and never mutated, so any thread may parse.
- **Error states**: No error is thrown; failure is nothing.
- **Offline / disconnected state**: Not applicable: The parser has no network access.
- **Cancellation**: Not applicable: The parser has no concern of this kind beyond what Behavioral Requirements state.

