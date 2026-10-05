
- **Null / empty input**: An empty list sums to zero in the requested currency (`sum-of-list`); an empty currency string is accepted by the type, because only the three-letter shape rule in the currency-code spec validates codes.
- **Boundary values**: Seconds times rate is computed in the platform integer width, so a product that exceeds it overflows, which traps in Swift; the type adds no guard. Zero hundredths is a valid amount.
- **Concurrent access**: The type is an immutable value and is safe to share across threads.
- **Error states**: Mixed-currency arithmetic and comparison fail as programmer errors rather than returning an error value.
- **Offline / disconnected state**: Not applicable: The money type has no network access.
- **Cancellation**: Not applicable: The money type has no concern of this kind beyond what Behavioral Requirements state.

