
- **Null / empty input**: Empty text parses to nothing; a zero amount displays as `0.00` with the symbol.
- **Boundary values**: A leading decimal point (`.5`) and a trailing one (`150.`) are accepted; a separator at either end of a run of separators is refused. A single group of exactly three digits after a non-zero integer part is treated as grouping in locales that group with that character.
- **Concurrent access**: The formatter holds only a currency code and a locale and is an immutable value, safe to share.
- **Error states**: Parsing returns nothing for every malformed input and never an approximation; display cannot fail.
- **Offline / disconnected state**: Not applicable: The formatter has no network access.
- **Cancellation**: Not applicable: The formatter has no concern of this kind beyond what Behavioral Requirements state.

