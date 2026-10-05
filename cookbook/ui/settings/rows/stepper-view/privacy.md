
- **Data collected**: Not applicable — the component collects no data of
  its own; it only displays a value supplied by the view model and
  reports stepper changes back through the view model's value.
- **Storage**: Not applicable — source performs no read/write to disk or
  any other store directly; persistence is owned by the view model and
  its underlying observer, which are not part of this file.
- **Transmission**: Not applicable — no networking call appears anywhere
  in source.
- **Retention**: Not applicable — the view retains only its own
  subviews (label, value label, stepper) and its reference to the view
  model for its own lifetime; it persists nothing itself beyond that.

