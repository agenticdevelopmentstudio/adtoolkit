
- **Data collected**: the plan operation reads and returns each record's
  `path` (an absolute filesystem path) and `remote` (a git remote URL read
  elsewhere and passed through) exactly as its inputs supply them, with no
  inspection, redaction, or transformation.
- **Storage**: None — the plan operation returns a plan value to its caller
  and persists nothing itself; writing the plan's records to a database is
  a separate component's responsibility.
- **Transmission**: None — the reconciler makes no network call.
- **Retention**: Not applicable — a plan value's lifetime is entirely the
  caller's responsibility once the plan operation returns.

