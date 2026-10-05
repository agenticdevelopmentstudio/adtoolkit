
- **Data collected**: Not applicable — the component collects no data of
  its own; it only displays a value supplied by the view model and reports
  radio selections back through it.
- **Storage**: Not applicable — source performs no read/write to disk, or
  any other persistent store; persistence, if any, is owned by the view
  model layer, which is not part of this component.
- **Transmission**: Not applicable — no networking call appears anywhere
  in source.
- **Retention**: Not applicable — the view retains only its own child
  views (the label, the radio buttons, the two groups) and its reference
  to the view model for its own lifetime; it persists nothing beyond
  that.

