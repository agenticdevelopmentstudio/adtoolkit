
- **Null/empty input**: Setting the panel list to `[]` MUST leave the
  sidebar with no sections and no rows, with no crash. Setting the search
  query to `""` MUST match every panel (see **empty-query-inclusion**).
- **Boundary values**: Index-based selection, visibility querying, and the
  internal row-id resolver MUST behave correctly at the first (`0`) and
  last (`count - 1`) valid indices, and MUST silently no-op (rather than
  trap) for any index outside that range, since each guards against
  out-of-bounds access before acting.
- **Concurrent access**: Not a runtime race condition to defend against —
  the component's state is confined to a single, serialized execution
  context by construction, so simultaneous mutation of the panel list,
  search query, or selection callback from multiple threads is rejected at
  compile time; the source adds no additional locking because none is
  needed.
- **Error states**: Not applicable — setting the panel list, the search
  query, and index-based selection are synchronous, always-succeeding,
  in-memory operations with no fallible dependency (no network, disk, or
  database call) anywhere in this component.
- **Offline/disconnected state**: Not applicable — no networking of any
  kind appears anywhere in this component.
- **Query with repeated whitespace**: A search query containing multiple
  consecutive spaces (e.g. `"a  b"`) MUST narrow the same way a
  single-spaced query does — splitting on whitespace omits empty
  subsequences by default, so extra spacing does not introduce a term that
  trivially matches everything.
- **Panel with a blank title**: A panel whose descriptor title is `""`
  renders a row with an empty label; this component performs no
  validation or fallback text for a blank title.
- **Descriptor mutated after the panel list is set**: A descriptor's
  title, icon, disabled flag, and section fields are all individually
  observable, but this component subscribes to none of them — rows are
  built once, when the panel list or a search-query change triggers a
  rebuild. A panel's descriptor mutated after the sidebar has already been
  populated leaves that row showing stale text/icon/disabled-state until
  some later panel-list or search-query change triggers a rebuild; this
  component does not subscribe to the descriptor's own change
  notifications or otherwise refresh a row automatically.

