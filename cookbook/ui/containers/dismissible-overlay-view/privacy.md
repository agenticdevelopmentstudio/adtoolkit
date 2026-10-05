
- **Data collected**: None. The instance retains only the caller-supplied
  `material` and `onDismissed` closure; it originates no data of its own.
- **Storage**: Not applicable — the source performs no persistence of any
  kind.
- **Transmission**: Not applicable — no network I/O appears anywhere in
  this file.
- **Retention**: None beyond the view's own lifetime; state is discarded
  once dismissal removes it from its superview and the caller releases its
  reference.

