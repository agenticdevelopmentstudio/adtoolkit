
- **Data collected**: None — the component holds only the `title`,
  `subtitle`, `summary`, `status`, `titleTrailingStatus`, and accessory
  values passed to it by the caller; it originates no data of its own.
- **Storage**: Not applicable — the component performs no persistence of
  any kind. (A companion fold-memory helper persists which cards are
  folded, but that is a separate file the host wires in; it is not part of
  this source.)
- **Transmission**: Not applicable — the source performs no network I/O.
- **Retention**: Not applicable — the view retains only its own subviews
  and the caller-supplied values for its own instance lifetime.

