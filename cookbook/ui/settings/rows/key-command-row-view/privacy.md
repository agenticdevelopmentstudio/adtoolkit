
- **Data collected**: The row surfaces the one piece of user-authored data
  it edits — the chord and enabled flag for the command's id — but does not
  collect anything beyond what the user types into the capture field or
  toggles on the switch.
- **Storage**: This component performs no storage of its own; it delegates
  persistence entirely to the registry's own binding-write operation, which
  writes into the shared settings store — a component not covered by this
  file.
- **Transmission**: Not applicable — no networking call appears anywhere in
  source.
- **Retention**: Not applicable to this file — the row retains only its own
  subviews, its command reference, its registry reference, and its own
  transient edit state (pending shortcut, mid-edit flag, refusal message)
  for its own lifetime; how long the committed binding itself is retained
  is the registry/settings-store layer's concern, not this file's.

