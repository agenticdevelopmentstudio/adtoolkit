
- **Data collected**: None — the component holds only the caller-supplied
  group-view/panel-heading-view instances it is given, plus its own
  internal stack and theme-change observer.
- **Storage**: Not applicable — the source performs no read/write to disk
  or any other store.
- **Transmission**: Not applicable — no networking call appears anywhere
  in the source.
- **Retention**: Not applicable — the view retains its stack, its added
  arranged children, and its theme observer only for its own lifetime; it
  persists nothing beyond that.

