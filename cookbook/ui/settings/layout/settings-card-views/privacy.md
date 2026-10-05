
- **Data collected**: The search field's text value holds whatever search
  string the user types; it exists only in memory for the lifetime of the
  view and the state it is bound to. Nothing else in this vocabulary
  collects data.
- **Storage**: Not applicable — nothing in this vocabulary persists title,
  text, or placeholder anywhere; any persistence is entirely the caller's
  concern.
- **Transmission**: Not applicable — no network or IPC call appears
  anywhere in this vocabulary.
- **Retention**: Not applicable — no data outlives the view instances that
  hold it in memory.

