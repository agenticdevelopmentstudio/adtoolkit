
- **Data collected**: A checkout value holds the caller's local filesystem
  `directory` path and, when present, the checkout's git `branch` name.
  Both are local workspace metadata the caller already possesses; creating
  a checkout does not read anything from disk beyond resolving `directory`'s
  symlinks.
- **Storage**: None — a checkout persists nothing; a value lives only as
  long as the caller retains it in memory.
- **Transmission**: None — creating or projecting a checkout makes no
  network call and transmits nothing.
- **Retention**: Not applicable — a checkout holds no state beyond the
  single value's lifetime; retention of any checkout the caller keeps is
  entirely the caller's responsibility.

