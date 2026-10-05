
- **Empty/missing input**: A repository id with zero rows → loading tabs'
  documented default tuple (**load-tabs-empty-default**); writing tabs
  with an empty tab list → every existing row for the repository id is
  deleted and `project_state.active_tab_id` is written `NULL`
  (**save-tabs-state-row-always-written**); saving an empty
  project-directories list → the table ends empty for the repository id
  (**project-directories-whole-replace**); setting pane state to an
  absent value on a key with no existing row is a no-op delete, not an
  error (the delete matches zero rows silently).
- **Distinguishing "empty" from "absent"**: `pane_state.value` is `TEXT
  NOT NULL`, so a caller can persist the empty string `""` as a real
  value, distinct from reading pane state returning nothing for a row
  that does not exist at all.
- **Malformed persisted data**: a `project_tabs`/`layout_nodes` row with
  an unparseable identifier is dropped rather than surfaced
  (**load-tabs-malformed-row-dropped**,
  **fetch-node-rows-malformed-id-dropped**, both tied to the
  pending **load-tabs-corrupt-row-signal** decision); a `layout_nodes` row with a
  `kind` outside {"leaf","split"}, a split row with other than exactly two
  children, or a tree with a dangling child reference instead throws an
  invalid-schema error rather than being silently dropped
  (**build-tree-unknown-kind-error**, **build-tree-split-child-count**,
  **build-tree-missing-node-error**) — this file has no test coverage
  exercising any of those three throw paths.
- **Boundary values**: Tab/node positions are stored as SQLite integers
  with no range check in this extension — a tab or sibling-child list
  whose index exceeds what the underlying binding call accepts is not
  guarded here; a thickness fraction of exactly `0.0` is a distinct, valid
  stored value from absent (unsized) per test vector 6.
- **Concurrent access to one repository id**: covered by
  **load-tabs-active-tab-consistency** above — the same instance cannot
  interleave a write between loading tabs' two reads, and a commit
  through another connection is not guarded against; concurrent access to
  two different repository ids is unaffected by each other (test
  vector 5).
- **Error states**: a SQLite prepare or step failure at any point in
  writing tabs or saving project directories throws a prepare-failure or
  execution-failure error from the inherited execute helpers and rolls
  back the open transaction (**save-tabs-atomic-rollback**); the
  rollback's own `ROLLBACK` statement discards its own result so a
  rollback failure cannot mask or replace the original error, which is
  rethrown unchanged.
- **Disk/filesystem failure mid-write**: not distinguished from any other
  execution-failure/prepare-failure case above — a full disk or a revoked
  file permission surfaces through the same inherited error path as a
  malformed statement; nothing in this extension retries or backs off.
- **Offline/disconnected**: Not applicable — this component makes no
  network call; its only external dependency is the local SQLite file the
  project database opened.
- **Cancellation/timeouts**: Not applicable — every operation in this
  extension is synchronous, so there is nothing to cancel; the only
  timeout in play is the connection-level busy-timeout already covered
  under **write-serialized-via-busy-timeout**.

