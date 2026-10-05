
- **Null/empty input**: an empty points list or an empty series list draws no
  lines; the source performs no check for either. A `null` value is a gap, not
  a zero (see gap-for-null-value, T6).
- **Boundary values**: exactly four series is the maximum accepted; five is
  refused (see refuses-fifth-series, T5/T10). A single series is accepted and
  shows no legend (T3).
- **Concurrent access**: not applicable; the component holds no state and
  renders purely from its inputs (see no-mutable-state).
- **Error states**: the only error the component raises is the range error for
  more series than the palette holds; it is raised before anything is drawn.
  Where the plot's container measures zero by zero, nothing is drawn — the
  test file mocks the measured box for exactly this reason.
- **Offline / disconnected**: not applicable; the component makes no network
  call and receives its points from the caller.

