
- **Data collected**: Not applicable — the component collects no data of
  its own; it only renders the color theme value it is given.
- **Storage**: Not applicable — source performs no read/write to disk,
  persistent storage, or any other store; the terminal-appearance
  resolution's fallback to the app's stored defaults is a read-only
  lookup for its own defaults.
- **Transmission**: Not applicable — no networking call appears anywhere
  in source.
- **Retention**: Not applicable — the view retains the resolved palette
  and its own subviews only for its own lifetime; it persists nothing
  beyond that.

