
- **Data collected**: None by this component itself. It manages an in-memory
  list of tab ids, group ids, display titles, and content references
  describing *how* tabs are arranged — never content the host chooses to
  display inside hosted content.
- **Storage**: In-memory only, for the life of the view. Nothing in this
  concept persists tab state to disk; any such persistence is entirely the
  host's own responsibility, outside this component.
- **Transmission**: Not applicable — no networking call appears anywhere in
  this concept.
- **Retention**: None beyond the view's own lifetime; all tab and edge state
  is discarded when the view is deallocated.

