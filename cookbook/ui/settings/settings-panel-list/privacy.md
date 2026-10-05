
- **Data collected**: None of its own. The panel list and search query are
  transient, in-memory UI state describing which settings panels exist and
  what the reader has typed to filter them.
- **Storage**: None — the panel list and search query live only in memory
  for the lifetime of the component; this component writes nothing to any
  persistent store.
- **Transmission**: Not applicable — no networking call appears anywhere
  in this component.
- **Retention**: Not applicable — nothing this component holds outlives
  the component's own instance; there is no persistence to retain or
  expire.

