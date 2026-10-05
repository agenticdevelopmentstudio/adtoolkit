
- **Data collected**: None beyond what the caller already supplies —
  `label`, `choices` (ids/titles/details), and the resulting `selection`
  are reported only to the caller's own `onChange` closure, in-process.
- **Storage**: Not applicable — source performs no read/write to disk or
  any other store; if a caller wants to remember a filter across
  launches, that persistence and its restoration via the selection-setting
  operation are the caller's responsibility, not this file's.
- **Transmission**: Not applicable — no networking call appears anywhere
  in source.
- **Retention**: The instance retains only `label`, `choices`, its own
  `selection`, `onChange`, and its own theme-change observer, for its own
  lifetime; it persists nothing beyond that.

