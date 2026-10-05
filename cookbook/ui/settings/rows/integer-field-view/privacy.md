
- **Data collected**: Not applicable — the component collects no data of
  its own; it only displays a value supplied by the view model and reports
  committed edits back through the view model's setting observer.
- **Storage**: Not applicable — neither source file reads or writes a
  platform storage mechanism directly. Persistence is owned by the range
  view model/setting-observer/setting chain, which is not part of these
  files; by default that chain routes through a settings-storage provider,
  so a committed value survives an app restart, but that guarantee lives
  outside this component.
- **Transmission**: Not applicable — no networking call appears anywhere in
  source.
- **Retention**: Not applicable — the view retains only its own subviews
  (the label, the text field, the wrapped field) and its reference to the
  view model for its own lifetime; it persists nothing itself beyond that.

