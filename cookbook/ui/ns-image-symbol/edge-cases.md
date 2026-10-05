
- **Null/empty input**: An empty name is not a system symbol and takes the
  fallback path; an absent description is carried through as absent.
- **Boundary values**: The fallback size is fixed at 16 by 16 points
  regardless of the size the caller wanted; the displaying control's symbol
  configuration does not resize a blank image to match a real symbol's
  intrinsic size.
- **Concurrent access**: Not applicable — the lookup holds no state; it
  creates a new image on every call.
- **Error states**: A missing symbol is the one failure the lookup handles,
  and it handles it by returning the blank fallback rather than reporting an
  error.
- **Offline/disconnected state**: Not applicable — the lookup uses only
  symbols installed with the operating system.
- **Silent fallback**: A misspelled symbol name produces a blank control with
  no diagnostic, so a typo is visible only by inspection (see Design Decisions).

