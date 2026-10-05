
- **Data collected**: Not applicable — the component captures a keyboard
  chord configuration (a key plus modifiers), not personal data, and only
  for as long as it is held in `pendingShortcut`/`displayedShortcut`.
- **Storage**: Not applicable — this component's own source performs no
  read or write to disk or any other persistent store; the source's own
  doc comment is explicit that this component "records and reports; it
  never saves." Persistence, if any, is owned by whatever the hosting row
  commits the chord to, which is outside this file.
- **Transmission**: Not applicable — no networking call appears anywhere in
  source.
- **Retention**: `pendingShortcut` and `displayedShortcut` are retained only
  in memory for the view's own lifetime. Neither is cleared by the manual
  recording-stop operation or anywhere else in this file — that operation
  only stops recording (see end-recording-force-stop); assigning and
  clearing both properties is entirely the caller's responsibility. Either
  property is overwritten whenever the caller sets a new value, or
  released when the view is deallocated; this file writes nothing to
  persistent storage.

