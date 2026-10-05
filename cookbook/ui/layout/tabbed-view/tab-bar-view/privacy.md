
- **Data collected**: None by this component itself. It holds only the tab
  ids, titles, and content references it is given, describing how tabs are
  arranged — never content a hosted item chooses to display.
- **Storage**: In-memory only, for the life of the bar instance. Nothing in
  this concept persists tab state to disk.
- **Transmission**: Not applicable — no networking call appears anywhere in
  this concept.
- **Retention**: None beyond the bar's own lifetime; all state is discarded
  when it is deallocated.

