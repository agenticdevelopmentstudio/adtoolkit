
- **Null / empty input**: An empty base is a name like any other: it is returned when free, or becomes ` 2` (a space and the number) when taken. An empty taken collection collides with nothing.
- **Boundary values**: The suffix search is unbounded, so a taken set with many consecutive suffixes costs one set lookup per step; the taken names are put in a set once.
- **Concurrent access**: Stateless pure functions over a caller-supplied snapshot of names; two callers racing on the same snapshot can pick the same name, which the caller must guard.
- **Error states**: Neither function can fail.
- **Offline / disconnected state**: Not applicable: The name rule has no network access.
- **Cancellation**: Not applicable: The name rule has no concern of this kind beyond what Behavioral Requirements state.

