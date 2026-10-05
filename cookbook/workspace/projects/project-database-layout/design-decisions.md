
**Decision**: Whole-arrangement replace instead of a diff: `saveTabs` and `saveProjectDirectories` both delete everything for `repoID` and reinsert from the argument, rather than diffing against what is stored.
**Rationale**: the caller already holds the complete, current arrangement in memory (there is no incremental "move this one tab" entry point), so a diff would duplicate state the caller already reconciled for no benefit. Trade-off: every save rewrites every row for `repoID`, even when only one field changed, and any two-statement read racing a save sees a representation that briefly does not exist (**load-tabs-active-tab-consistency**).
**Approved**: pending

**Decision**: `pane_state.node_id` carries no foreign key: The `pane_state` table's `repo_id` cascades from `git_repo`, but its `node_id` column references no other table (`ProjectDatabase.swift`).
**Rationale**: a pane's node id changes shape across saves — a leaf can be replaced by a different leaf carrying the same visual slot — so a hard foreign key to `layout_nodes.id` would either block a legitimate rewrite or require deleting and reinserting `pane_state` on every save regardless of whether that pane survived. Trade-off: orphaned `pane_state` rows are only removed by the application-level sweeps in **save-tabs-pane-state-orphan-sweep** and **prune-nested-pane-state-scope**; a caller that saves tabs through a path other than `saveTabs` (there is none in this extension) could leave orphans behind indefinitely.
**Approved**: pending

**Decision**: Content-change sweep beyond id-based orphaning: `saveTabs` deletes a `pane_state` row when a still-present node id's leaf `contentType` changed, not only when the id itself disappeared.
**Rationale**: a node id can be reused across a rebuild for a pane that now shows different content (per `LayoutNode.swift`'s `reshaped(toMatch:)` id-reuse contract), and pane state keyed to the old content (e.g. a scroll position for a file that is no longer there) would otherwise silently apply to the new content. Trade-off: this requires reading the previous arrangement's leaf content types before the delete, adding a second full tree walk to every `saveTabs` call.
**Approved**: pending

**Decision**: `activeTabID` validated on write, not on read: `saveTabs` drops an `activeTabID` that names no tab in `tabs` to `NULL` before persisting; `loadTabs` performs no equivalent check on the way out (**load-tabs-active-tab-consistency**).
**Rationale**: at write time the full, authoritative `tabs` array is right there in the same call; at read time, re-validating would mean either a second query or holding both result sets in a shared transaction, which the current two-statement read does not do. Trade-off: the write-side guarantee only holds until the next write from any caller; a read racing a concurrent write is not covered by it, which is exactly the residual gap load-tabs-active-tab-consistency describes.
**Approved**: pending

**Decision**: `working_directory` empty string means unset, not "here": An empty `working_directory` column maps to `nil`, never to a `URL` for the empty path or the current directory.
**Rationale**: `TabRecord.workingDirectory == nil` has an existing meaning elsewhere in the type ("use the project directory"); coercing an empty string to a concrete `URL` would silently reassign that meaning to whatever directory the process happened to be running in when the row was read. Trade-off: `isDirectory: true` is forced on every non-empty value even when the directory no longer exists on disk, so a moved or deleted working directory round-trips as a URL that fails to resolve rather than as `nil`.  
**Approved**: pending

**Decision**: Rows dropped for an unparseable identifier (`project_tabs` and `layout_nodes`) are excluded silently: loading tabs and reading node rows throw nothing, log nothing, and give the caller no signal (`load-tabs-corrupt-row-signal`).
**Rationale**: The source guards each row with a failing-parse early return and the file contains no logging call; this extension is the schema's only writer, so a bad identifier could arise only from tampering. Closing it would need either a decision that tampering is out of scope or an error or signal path added to loading tabs.
**Approved**: pending

