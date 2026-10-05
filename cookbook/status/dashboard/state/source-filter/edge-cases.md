
- **Empty selection**: toggling off every source MUST give an empty set. For the activity panel, this hides every row that has a known `platform` whenever more than one source exists. Rows whose `platform` is null or missing still show, because the consumer lets them through.
- **Unknown source value**: the source type rules this out at compile time. A value forced in some other way MUST be added to or removed from the in-memory set like any other value, because Source Filter does no runtime check. The set's size can then exceed 7.
- **Source added to the fixed list later**: new mounts MUST include it in the default. A use that is already mounted does not pick it up until it starts again.
- **Rapid repeated toggles**: each call MUST flip membership once, based on the latest queued state (source-filter-007).
- **Update applied more than once for the same input**: the result MUST be the same as a single application, because the update has no side effects.
- **Reload or remount**: the selection MUST reset to all-selected. Source Filter persists nothing (see Design Decisions).
- **Server render**: Source Filter MUST render the default all-selected set on a server-rendering pass. It touches no client-only API.
- **Null or empty input, timeouts, cancellation, network loss, storage errors**: not applicable. Source Filter takes no arguments, and its only operation is a synchronous in-memory set update with no I/O.

