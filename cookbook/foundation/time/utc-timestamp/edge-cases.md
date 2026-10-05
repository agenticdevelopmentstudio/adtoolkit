
- **Null / empty input**: Empty text reads as nothing in every reader, and a duration involving it is zero.
- **Boundary values**: Leap days are accepted only in leap years (divisible by 4 and not 100, or by 400). Years are written with four digits; epoch values before year 0 or after year 9999 are not supported. The fast path needs at least 19 bytes.
- **Concurrent access**: All functions are stateless and pure apart from the clock read in now.
- **Error states**: Unparseable input returns nothing or zero seconds; nothing throws.
- **Offline / disconnected state**: Not applicable: The wire instant type has no network access.
- **Cancellation**: Not applicable: The wire instant type has no concern of this kind beyond what Behavioral Requirements state.

