
- **Null / empty input**: An empty stamp sequence yields no spans; an empty interval list yields an empty union and a zero length.
- **Boundary values**: A gap equal to the idle gap joins; one unit more splits. Touching intervals merge. A single stamp yields a zero-length span.
- **Concurrent access**: The splitter is a mutable value type with no lock; each owner uses its own. The static functions are pure.
- **Error states**: No operation fails. Out-of-order stamps are outside the contract: the split would compute a negative gap and keep joining the run.
- **Offline / disconnected state**: Not applicable: The algorithms has no network access.
- **Cancellation**: Not applicable: The algorithms has no concern of this kind beyond what Behavioral Requirements state.

