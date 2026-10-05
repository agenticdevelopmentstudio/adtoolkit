
- **Data collected**: None by this component — `paneName` is a display
  string supplied by the caller, held only for display.
- **Storage**: In-memory only, for the view's lifetime; nothing is written
  to disk, persistent settings storage, or any other store by this file.
- **Transmission**: Not applicable — no networking call appears anywhere in
  this file.
- **Retention**: None beyond the view's lifetime; state is discarded when
  the pane's own view controller removes and releases the instance.

