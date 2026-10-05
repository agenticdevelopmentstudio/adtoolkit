
- **Null / empty input**: A quantity of zero is nothing and stays nothing.
- **Boundary values**: An exact multiple is unchanged in upward mode; the exact half goes up in nearest mode; an increment of one leaves the value unchanged in both modes.
- **Concurrent access**: It is a stateless pure function.
- **Error states**: It never fails; a very large value times two could overflow the integer width, which traps in Swift, and no guard is added.
- **Offline / disconnected state**: Not applicable: The rounding rule has no network access.
- **Cancellation**: Not applicable: The rounding rule has no concern of this kind beyond what Behavioral Requirements state.

