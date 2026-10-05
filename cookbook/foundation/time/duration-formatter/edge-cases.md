
- **Null / empty input**: Empty or whitespace-only text parses to nothing; zero seconds formats as `0m`, `0.00` and `0:00:00`.
- **Boundary values**: Hours are never wrapped, so 90,000 seconds is `25h` and `25:00:00`; a digit run of seven digits is refused; a clock with minutes of 60 or one-digit minutes is refused.
- **Concurrent access**: Stateless pure functions.
- **Error states**: Parsing returns nothing; formatting cannot fail. Very large second counts could overflow the integer width in the decimal-hours multiplication, which traps in Swift; the type adds no guard.
- **Offline / disconnected state**: Not applicable: The formatter has no network access.
- **Cancellation**: Not applicable: The formatter has no concern of this kind beyond what Behavioral Requirements state.

