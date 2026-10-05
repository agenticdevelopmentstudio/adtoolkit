
- **project-opening-conformance**: The manager MUST conform to the
  project-opening interface — supplying an open-project operation and a
  close-project operation, each keyed by a repository id — and MUST
  publish its state so another component can observe it.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **shared-singleton**: The manager MUST expose one process-wide shared
  instance.
- **open-window-setting-key**: The manager MUST record whether a
  project's window was open at quit as a row in the project-settings
  store, keyed by the setting key `"window.open"`, scoped per repository
  id rather than kept in an app-wide preference, so the flag is deleted
  along with the project row it belongs to rather than surviving it.
- **injectable-collaborators**: The git client, the command registry, and
  the language-services factory MUST each be a public, externally
  settable property — defaulting to the shared git client, absent, and
  absent respectively — so a test or an alternate host can substitute a
  throwaway git client, decline command-palette integration, or decline
  language services without subclassing.
- **attach-registers-opener**: Attaching to a coordinator MUST store the
  given coordinator by a weak reference and MUST register the manager as
  that coordinator's project-opening implementation.
- **front-window-controller-fallback-chain**: The frontmost-window-controller
  lookup MUST return, in order: the window controller of whichever window
  currently has key status; failing that, the first of this manager's
  window controllers found among the app's currently ordered windows;
  failing that, the controller for the most recently opened project —
  returning the first of the three that resolves to a value.
- **open-workspaces-derived**: The open-workspaces list and the
  open-window-controllers list MUST both be computed by mapping the
  open-order list through the open-controllers table, filtering out any
  id no longer present, rather than maintained as separately stored
  lists.
- **refresh-publishes-then-notifies**: Refreshing the open-workspace-ids
  list MUST assign it from the open-order list filtered by membership in
  the open-controllers table, and MUST invoke the open-projects-changed
  callback only after that assignment completes.
- **every-mutation-site-refreshes**: Every operation that adds to or
  removes from the open-controllers table — adopting a window for
  scripting, forgetting an adopted window, opening a project, and the
  window-close handling a close observer installs — MUST refresh the
  open-workspace-ids list after the mutation.
- **adopt-for-scripting-idempotent**: Adopting a window for scripting
  MUST return immediately, registering nothing again, when the
  open-controllers table already holds an entry for that controller's
  project id.
- **adopt-for-scripting-registers-without-persisting**: On the
  non-idempotent path, adopting a window for scripting MUST insert the
  controller into the open-controllers table and the open-order list, add
  its id to the adopted-for-scripting set, and install a close observer
  that does not record open state, and MUST NOT write the window-open
  flag in either direction.
- **forget-for-scripting-guarded**: Forgetting an adopted window MUST
  remove the controller from the open-controllers table, the open-order
  list, and the adopted-for-scripting set, and MUST remove its close
  observer, only when the table's current entry for that id is that exact
  controller and that id is present in the adopted-for-scripting set;
  otherwise it MUST do nothing.
- **project-controller-lookup-nil-for-adopted**: Looking up a project's
  controller MUST return absent for a repository id whose window was
  registered by adopting it for scripting rather than built by opening a
  project, because adopting a window for scripting never inserts into the
  project-controllers table.
- **open-project-raises-existing-window**: When the open-controllers table
  already has an entry for the repository, opening a project MUST update
  that existing project's stored data, show its window, order it to the
  front, and offer the app the foreground, and MUST return without
  building a new workspace or controller.
- **no-database-open-failure-signal**: Opening a project MUST have no
  return value and MUST NOT throw or await; when no database is attached,
  its only response MUST be one error-level log call — no return value,
  thrown error, or callback tells the caller (a menu action or a
  double-click in the project browser) that nothing happened, so the user
  sees no window and no explanation. The failure MUST be logged, not
  surfaced.
- **open-project-tolerates-missing-language-factory**: When the
  language-services factory is absent, or returns nothing, opening a
  project MUST log that fact at info level and MUST continue building the
  workspace and window with no language services.
- **open-project-starts-language-services**: When the language-services
  factory returns a value for the project's directory, opening a project
  MUST start those language services before constructing the project
  controller.
- **project-controller-precedes-window**: Opening a project MUST construct
  the project controller and store it in the project-controllers table
  before constructing the window controller, and MUST pass that same
  project controller as the window's tab-item data source at construction
  rather than assigning it afterward.
- **callback-wiring-checks-current-controller**: The tabs-changed callback
  and the tab-items-need-refresh callback that opening a project assigns
  to the new project controller MUST each hold the manager, the window
  controller, and the project controller by weak reference, and MUST call
  through to the window only when the open-controllers table's current
  entry for that repository is still reference-identical to the captured
  project controller.
- **will-change-cancels-pending-persist**: The will-change-tabs callback
  that opening a project assigns MUST cancel that project controller's
  pending tab persistence.
- **open-project-registration-order**: On the new-project path, opening a
  project MUST, in this order: register the controller in the
  open-controllers table and append its id to the open-order list; show
  the window, order it to the front, and offer the app the foreground;
  refresh the open-workspace-ids list; install the close observer
  (recording open state) and the became-key observer; start the project
  controller's own opening work as an independent, concurrently running
  unit of work; write the window-open flag as open.
- **open-fires-changed-notification-after-window-is-frontmost**: Opening a
  project MUST refresh the open-workspace-ids list — and therefore invoke
  the open-projects-changed callback — only after the window has been
  registered, ordered to the front, and offered the foreground, and MUST
  NOT do so at the point the controller is first registered.
- **initial-key-notification-not-guaranteed**: Because the window is
  ordered to the front and given key status before the became-key
  observer is installed, a newly opened window's own first became-key
  notification MAY or MAY NOT be seen by that observer, and opening a
  project MUST NOT add any synchronization to force either outcome.
- **close-project-delegates-and-no-ops-on-unknown-id**: Closing a project
  MUST close the window belonging to the open-controllers table's entry
  for that repository id when one exists, and MUST do nothing when it
  does not.
- **shutdown-all-language-services-runs-concurrently**: Shutting down all
  language services MUST collect every currently open project's language
  services and MUST shut them all down concurrently, as a single group of
  concurrent operations, never sequentially.
- **shutdown-all-language-services-drains-pending-teardowns**: After that
  group of concurrent operations completes, shutting down all language
  services MUST also wait for the pending-teardowns registry to drain, so
  a language service whose shutdown was started by an earlier window
  close — one already removed from the open-controllers table — is still
  waited for.
- **restore-open-projects-requires-coordinator**: Restoring open projects
  MUST return immediately, reopening nothing, when no coordinator has
  been attached.
- **restore-plan-is-pure**: Computing the restore plan MUST be a pure
  computation with no side effect, given a list of repositories, a
  was-open predicate, and an exists-on-disk predicate, and MUST compute a
  set to reopen — every repository for which both predicates are true —
  and a set to forget — every repository for which the was-open predicate
  is true and the exists-on-disk predicate is false.
- **restore-forgets-missing-folders**: For every repository in the
  restore plan's forget set, restoring open projects MUST log at info
  level and MUST write the window-open flag as closed, clearing the
  persisted flag instead of reopening a window onto a missing folder.
- **restore-reopens-existing-folders**: For every repository in the
  restore plan's reopen set, restoring open projects MUST open that
  project.
- **window-open-flag-read-write**: Reading the window-open flag MUST read
  the `"window.open"` setting through the database's per-repository
  setting lookup and MUST treat exactly the string `"1"` as open; writing
  the window-open flag MUST write `"1"` for open and remove the row
  (rather than writing any other value) for closed.
- **window-open-read-failure-defaults-closed**: When the database's
  setting lookup fails, reading the window-open flag MUST log the failure
  at error level and MUST return closed — the same value it returns for a
  project whose window was genuinely never marked open.
- **became-key-refreshes-checkouts**: The became-key observer MUST, on
  firing, look up the project controller for that repository id and, when
  found, start that controller's checkout refresh as an independent,
  concurrently running unit of work.
- **close-flag-respects-app-termination**: In the window-close handling,
  when that close observer records open state, writing the window-open
  flag as closed MUST happen only when the app is not in the middle of
  terminating, so a window the platform closes on its way out of a
  quitting app is not recorded as the user having closed it.
- **close-drops-controller-and-reregisters-survivors**: The close
  handling MUST remove the closing project's entry from the
  project-controllers table and mark that controller closed
  synchronously, then MUST re-register commands on every remaining value
  in the project-controllers table, so a branch-command id that collided
  across two windows over the same repository is handed back to the
  surviving window.
- **close-captures-teardown-target-before-removing-it**: The close
  handling MUST capture both the project-controllers table's removed
  entry for that id and the open-controllers table's entry's language
  services before removing that id from the open-controllers table, the
  open-order list, and the adopted-for-scripting set, and MUST route the
  teardown it schedules through the captured project controller's own
  shutdown when one exists, or through the captured language services'
  shutdown only when it does not — never both.
- **close-observer-uses-nil-queue**: The close observer MUST be installed
  so its handler runs synchronously, on the same thread and in the same
  run-loop turn as the close, rather than deferred through an enqueued
  delivery.
- **close-fires-on-project-closed-before-removal**: The close handling
  MUST invoke the project-closed callback while the open-controllers
  table still holds the closing project — i.e. before removing that
  entry.
- **close-teardown-added-to-shared-registry**: The close handling MUST
  hand its teardown to the pending-teardowns registry rather than
  starting an unmanaged, unheld unit of concurrent work, so shutting down
  all language services can find and wait for it even after this
  project's controller and window have already left every other
  collection.

