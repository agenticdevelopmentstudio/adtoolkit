
- **Null/empty input**: Empty text is a blank: accepted as no amount when allowed, refused otherwise.
- **Boundary values**: Both ends of the range are accepted.
- **Concurrent access**: Main thread only.
- **Error states**: Unparseable and out-of-range text are refused silently by reverting; no message is shown.
- **Offline/disconnected state**: Not applicable.
- **Currency change**: Asking the formatter afresh re-renders the amount when the row refreshes.

