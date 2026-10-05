
- **Data collected**: None. The view holds the message and its attribution it was constructed with, purely to render them; it does not read, copy, or forward that data anywhere beyond drawing it and the caller-supplied `Actions` closures.
- **Storage**: None. All state (`message`, `attribution`, `isHovered`, `isSelected`) is held in memory only, for as long as the view instance exists.
- **Transmission**: None. This view performs no networking; whatever happens after `onOpen`/`onJump`/`onSelect` fire is the caller's responsibility.
- **Retention**: None beyond the view's own lifetime — the message data is released when the row view is deallocated or replaced.

