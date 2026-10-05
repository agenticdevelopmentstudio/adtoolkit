
- **Data collected**: Not applicable - the component collects no data of
  its own; it only displays a font supplied by the view model and reports
  font picks back to it.
- **Storage**: Not applicable - source performs no read/write to disk or
  any other store; persistence, if any, is owned by the view model and
  its setting observer, which are not part of this file.
- **Transmission**: Not applicable - no networking call appears anywhere in
  source.
- **Retention**: The view retains only its own constituent elements and
  its reference to the view model for its own lifetime; it persists
  nothing beyond that.

