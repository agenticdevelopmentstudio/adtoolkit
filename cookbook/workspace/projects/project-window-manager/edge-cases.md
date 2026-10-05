
- **Null and empty input**: The language-services factory and the command
  registry being absent are documented, supported configurations, not
  gaps — opening a project logs and continues with no language services
  (**open-project-tolerates-missing-language-factory**), and every
  command-registry call elsewhere becomes a no-op. The coordinator being
  absent (never attached) makes restoring open projects a no-op
  (**restore-open-projects-requires-coordinator**); it also leaves
  opening a project unable to pass its database guard — see
  **no-database-open-failure-signal** (MUST/SHOULD as annotated on each
  cited requirement).
- **Boundary values**: The open-order list and the open-controllers table
  may hold zero, one, or many project ids; every value derived from them
  (the open-workspaces list, the open-window-controllers list, the
  frontmost-window-controller lookup's final fallback) MUST handle zero
  entries by producing an empty list or nothing, with no special case in
  the source for either end (MUST, by the absence of any guard).
- **Concurrent access**: Every mutation of the open-controllers table,
  the open-order list, the project-controllers table, the
  adopted-for-scripting set, and the key-observer table is confined to
  the manager's main execution context (**confines-to-ui-thread**), so
  no interleaving between opening a project, closing a project, adopting
  a window for scripting, and the notification-driven handlers can
  observe a torn collection (MUST). One race the source does guard
  explicitly: opening a project's own completion work and a later close
  of the same project both reach the same project controller, and
  **callback-wiring-checks-current-controller**'s identity check is what
  stops a stale controller's callback from reaching a window that has
  moved on to a different controller (see vector -007).
- **Error states**: A failed setting read or write is logged and answered
  with a default (closed, for a read; the write simply does not happen)
  rather than propagated to any caller (**window-open-read-failure-defaults-closed**,
  **window-open-flag-read-write** — both MUST, by their failure
  handling). Opening a project's own database-missing guard is the one
  error path in this file with no signal at all beyond the log line; see
  **no-database-open-failure-signal**.
- **Offline or disconnected state**: Not applicable in the network sense
  — every operation this file performs is local: the database, the
  filesystem check the restore plan's exists-on-disk predicate performs,
  and git through the project controller (documented in
  `adtoolkit://cookbook/workspace/projects/project-controller`).
  None of it reaches a remote host.
- **Cancellation and timeouts**: Opening a project's own opening work is
  not cancelled by a subsequent close of that project; the in-flight work
  keeps running to completion, and it is the project controller's own
  closed-state guard — not anything in this file — that stops it from
  persisting stale data or reloading a dead window (see
  `adtoolkit://cookbook/workspace/projects/project-controller`'s
  reconcile-aborts-after-a-late-close requirement, and vector -007
  above). Shutting down all language services waits for its group of
  concurrent operations and then for the pending-teardowns registry to
  drain, unconditionally, with no timeout of its own; the roughly
  2.5-second-per-server ceiling belongs to the subprocess channel's own
  termination step, documented on the pending-teardowns registry.
- **Missing file or unreachable server**: A repository whose folder was
  deleted or renamed since the app last quit is not distinguished from
  any other flagged-open project until the restore plan checks whether
  it still exists on disk; it is moved to the forget set and its
  persisted flag is cleared rather than reopened onto an empty tree
  (**restore-forgets-missing-folders**, see vector -011). A repository
  opened directly (not via restore) whose folder is already missing is
  not checked here at all — the workspace and controller are built
  regardless, and the resulting git failure is the project controller's
  to degrade gracefully from, not this file's.

