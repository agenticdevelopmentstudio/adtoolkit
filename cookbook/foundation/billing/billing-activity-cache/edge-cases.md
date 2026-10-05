
- A session with no events returns an empty history and stores cursor from the read result.
- An event stored with an earlier timestamp than held values is merged in order, not appended.
- Concurrent calls for different sessions are safe because the underlying cache is locked; two concurrent calls for the same session may both read the same tail and merge identically.

