
### Reading tabs

- **load-tabs-empty-default**: Loading tabs MUST return `(tabs: [],
  activeTabID: nil, enabledEdges: [top])` for a repository id with no
  `project_tabs` or `project_state` rows.
- **load-tabs-order**: MUST return tabs ordered ascending by the
  `project_tabs.position` column, via `ORDER BY position` in the query.
- **load-tabs-malformed-row-dropped**: MUST silently exclude a
  `project_tabs` row from the returned list when its `id` or
  `root_node_id` column fails to parse as a valid identifier.
- **load-tabs-corrupt-row-signal**: Neither loading tabs nor reading node rows throws, logs, or otherwise signals when a row is dropped for failing identifier parsing; a caller has no way to detect that its persisted arrangement came back incomplete (see Design Decisions).
- **load-tabs-edge-fallback**: MUST default a tab's edge to the top edge
  when the stored `edge` column is `NULL` or fails to parse as a valid
  edge value.
- **load-tabs-title-fallback**: MUST default a tab's title to the empty
  string when the stored `title` column is `NULL`.
- **load-tabs-group-id-fallback**: MUST fall back to the tab's own id for
  its group id when the stored `group_id` column is `NULL` or fails
  identifier parsing, defaulting a tab record's group id to its own id
  when none was stored.
- **load-tabs-working-directory-empty-to-nil**: MUST map an empty-string
  `working_directory` column to an absent value rather than to a location,
  so an unset working directory round-trips as unset rather than as the
  process's current directory.
- **load-tabs-working-directory-is-directory-url**: MUST construct any
  non-empty `working_directory` value as a directory location, always
  marking it as a directory regardless of whether it currently exists on
  disk.
- **load-tabs-tree-reconstruction**: MUST reconstruct each tab's root
  layout-node tree from `layout_nodes` rows, resolving a split row into
  exactly two ordered children by position.
- **load-tabs-active-tab-default**: MUST read `active_tab_id` and
  `enabled_edges` from the single `project_state` row for the repository
  id, or fall back to (no active tab, the top edge alone) when no such row
  exists.
- **load-tabs-active-tab-consistency**: Loading tabs reads
  `project_tabs`/`layout_nodes` and `project_state` as two separate,
  non-transactional statements, and never re-validates the returned
  active-tab id against the returned tabs, unlike writing tabs' validation
  check on write. This component carries no concurrency-safety guarantee
  of its own and loading tabs is synchronous, so no write on the same
  instance can run between the two reads; a commit through a different
  connection to the same file between them can make the returned
  active-tab id name no tab in the result.
- **load-tabs-enabled-edges-fallback**: MUST discard a stored
  `enabled_edges` value that is empty, or that parses to zero valid edge
  entries, and keep the default (the top edge alone) rather than return an
  empty list.

### Writing tabs

- **save-tabs-whole-replace**: Writing tabs MUST replace the entire
  arrangement for a repository id: it deletes every existing
  `project_tabs`, `layout_nodes`, and `project_state` row for that
  repository id before reinserting from the given tabs.
- **save-tabs-atomic-rollback**: MUST wrap the whole replace in `BEGIN
  IMMEDIATE TRANSACTION` / `COMMIT`, and MUST roll back and rethrow the
  original error unchanged if any step fails, leaving the previously
  persisted arrangement intact.
- **save-tabs-default-enabled-edges**: The enabled edges MUST default to
  the top edge alone when the caller omits them.
- **save-tabs-tab-position**: MUST persist each tab's
  `project_tabs.position` as its index in the given tab list, in that
  order.
- **save-tabs-tree-insert-order**: MUST insert each tab's root node, and
  recursively its children, assigning a split's two children position 0
  and 1 in first/second order and a parent id equal to the split's own id.
- **save-tabs-active-tab-validated**: MUST validate the active-tab id
  against the given tab list and persist `NULL` for
  `project_state.active_tab_id` when it names no tab in that list, rather
  than persist a reference to a tab that was not saved.
- **save-tabs-state-row-always-written**: MUST always insert exactly one
  `project_state` row for the repository id, even when the validated
  active tab is absent, so the enabled edges still persist.
- **save-tabs-enabled-edges-canonical-order**: MUST persist the enabled
  edges as a comma-joined string in a fixed canonical order (top, right,
  bottom, left), filtered to only the edges present in the caller's
  argument — not in the argument's own order.
- **save-tabs-pane-state-orphan-sweep**: MUST delete every `pane_state`
  row for the repository id whose `node_id` is absent from the
  just-rewritten `layout_nodes` for that repository id.
- **save-tabs-pane-state-content-change-sweep**: MUST additionally delete
  a `pane_state` row for any `node_id` whose leaf content type differs
  between the previous arrangement and the new one, even when that node id
  is still present in the new `layout_nodes`.
- **insert-node-column-nulls-by-kind**: Inserting a node MUST write
  `NULL` for `orientation` on a leaf row and `NULL` for
  `content_type`/`pane_label` on a split row.

### Rebuilding the tree

- **build-tree-missing-node-error**: Rebuilding the tree MUST throw an
  invalid-schema error when a referenced node id — the root, or either
  split child — is absent from the fetched rows.
- **build-tree-split-child-count**: MUST throw an invalid-schema error
  when a row whose `kind` is split has any number of children other than
  exactly 2.
- **build-tree-unknown-kind-error**: MUST throw an invalid-schema error
  when a row's `kind` column is neither "leaf" nor "split".
- **build-tree-orientation-fallback**: MUST default a split's orientation
  to horizontal when the stored `orientation` value is `NULL` or fails to
  parse as a valid orientation.
- **build-tree-content-type-fallback**: MUST default a leaf's content
  type to the placeholder content type when the stored `content_type`
  column is `NULL`.
- **fetch-node-rows-malformed-id-dropped**: Reading node rows MUST
  silently exclude any `layout_nodes` row whose `id` column fails
  identifier parsing from the returned collection; this is the same class
  of silent drop as **load-tabs-corrupt-row-signal** above, one level lower.

### Pane state

- **pane-state-read**: Reading pane state MUST return the stored value
  for the exact (repository id, node id, key) triple, or nothing when no
  such row exists.
- **pane-state-write-upsert**: Setting pane state with a present value
  MUST upsert via `INSERT ... ON CONFLICT(repo_id, node_id, key) DO UPDATE
  SET value = excluded.value`, so writing the same triple twice replaces
  the row rather than duplicating it.
- **pane-state-write-nil-deletes**: Setting pane state with an absent
  value MUST delete the row rather than persist an empty string.
- **prune-nested-pane-state-scope**: Pruning nested pane state MUST
  delete only `pane_state` rows under (repository id, node id) whose key
  embeds at least one dot-separated identifier component absent from the
  given live-ids set, and MUST leave untouched any key with no identifier
  component.
- **prune-nested-pane-state-read-then-delete**: MUST fully exhaust the
  `SELECT` over candidate rows before issuing any `DELETE`, matching this
  component's own design rationale that deleting from a table while
  stepping a cursor over it is undefined in SQLite.

### Project directories

- **project-directories-order**: Loading project directories MUST return
  paths ordered by the stored `position` column.
- **project-directories-empty-means-none**: an empty `project_directories`
  result MUST be treated as "this project has no extra browsed
  directories," not as "this project has never been saved".
- **project-directories-whole-replace**: Saving project directories MUST
  delete every existing `project_directories` row for the repository id
  and reinsert the given paths at their list index as position, inside
  one transaction that rolls back and rethrows on failure.

### Concurrency and lifetime

- **caller-must-synchronize-cross-thread-access**: This component's
  underlying store MUST be treated as unsafe to share across concurrency
  domains without the caller's own synchronization; every operation in
  this extension inherits that lack of built-in isolation, so a caller
  MUST NOT share one instance across concurrency domains without its own
  synchronization.
- **write-serialized-via-busy-timeout**: a writer contending for the same
  database file MUST wait up to 5000ms (via SQLite's busy-timeout
  mechanism) before the underlying call surfaces a busy failure as an
  execution or prepare failure; this extension does not retry beyond that
  timeout.
- **cascade-delete-on-repo-removal**: deleting a `git_repo` row MUST
  cascade-delete every `project_tabs`, `layout_nodes`, `project_state`,
  `pane_state`, and `project_directories` row for that repository id, via
  the `ON DELETE CASCADE` foreign keys declared on each table's `repo_id`
  column. `pane_state.node_id` carries no foreign key of its own — which
  is why **save-tabs-pane-state-orphan-sweep** and
  **prune-nested-pane-state-scope** exist as explicit application-level
  sweeps rather than relying on cascade.

