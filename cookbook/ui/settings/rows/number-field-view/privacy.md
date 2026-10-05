
- **Data collected**: Not applicable — the component collects no data of
  its own; it only displays a value supplied by the view model and reports
  committed edits back through it.
- **Storage**: Not applicable — this component never reads or writes any
  persistent store directly. Persistence is owned by the view model layer,
  which is not part of this component.
- **Transmission**: Not applicable — no networking call is made anywhere in
  this component.
- **Retention**: Not applicable — the component retains only its own
  subviews (label, field) and its reference to the view model for its own
  lifetime; it persists nothing itself beyond that.

