
- **state-surface**: The project controller MUST expose its live state as a
  `checkouts` list and a `branchControllers` map from checkout to branch
  controller, both read-only from outside, as the only project-owned
  collections it maintains.
- **tab-item-data-source-conformance**: The project controller MUST be the
  one that answers every tab-item request itself, rather than delegating
  that responsibility to the workspace or to a branch controller.
- **required-workspace-optional-registry**: Constructing a project
  controller MUST accept a workspace as a required parameter with no
  default value, and a command registry as a required parameter (also with
  no default) whose value MAY be absent.
- **derived-git-client**: The git client MUST be computed from the
  workspace on every access rather than stored or constructed
  independently, so this controller and every branch controller it creates
  read git through the one client the workspace was given.
- **open-runs-serialized-reconcile**: Opening the project MUST run the
  serialized reconcile operation and MUST NOT itself perform any git read,
  checkout assignment, or tab persistence.
- **refresh-checkouts-runs-serialized-reconcile**: Refreshing checkouts
  MUST run the serialized reconcile operation, the same entry point opening
  uses.
- **reconcile-calls-chain-in-order**: The serialized reconcile operation
  MUST capture whatever reconcile is currently in flight, start a new one
  that awaits the in-flight one's completion before doing any work of its
  own, record itself as the new in-flight reconcile, and await its own
  completion — so two overlapping calls to opening or refreshing checkouts
  always run their reconciles in the order they were called, never in the
  order their own git reads happen to finish.
- **close-guard-brackets-reconcile-and-refresh**: The serialized reconcile
  operation MUST check the closed flag immediately before reconciling and
  again immediately after it returns, skipping reconciling entirely on the
  first check's failure and skipping the branch-controller refresh loop
  entirely on the second's.
- **branch-controllers-refreshed-after-reconcile**: When both close checks
  pass, the serialized reconcile operation MUST refresh every branch
  controller currently held.
- **mark-closed-is-synchronous-and-final**: Marking the project closed MUST
  take effect immediately, within the same step as the call that reaches
  it — not deferred to a later asynchronous continuation — setting the
  closed flag and unregistering every current branch controller's commands.
- **shutdown-closes-then-stops-language-services**: Shutting down MUST
  mark the project closed and then stop the workspace's language services,
  in that order.
- **reregister-commands-guard**: Reregistering commands MUST return
  immediately, registering nothing, when the project is closed or when
  there is no command registry.
- **reregister-commands-fills-only-gaps**: When that guard passes,
  reregistering commands MUST register, with the command registry, every
  command of every current branch controller whose id is not already
  registered, and MUST leave every already-registered id untouched.
- **branch-controller-lookup-resolves-symlinks**: Looking up a branch
  controller by directory MUST resolve symlinks in the given directory
  before comparing it against the branch controllers' key directories, and
  MUST return the first match by directory equality.
- **reconcile-aborts-after-a-late-close**: Reconciling MUST read the
  current checkouts and then, before mutating the checkout list, the
  branch-controller map, or persisting tabs, MUST return immediately if the
  project has become closed during that read.
- **reconcile-commits-fresh-checkouts**: Once past that guard, reconciling
  MUST assign the freshly read checkouts to the checkout list and MUST
  synchronize the branch controllers before computing a tab plan.
- **tab-plan-via-reconciler**: Reconciling MUST compute its plan from the
  stored tabs (or an empty list when none are stored), the just-assigned
  checkouts, and the project's directory.
- **unchanged-plan-writes-nothing**: When tabs were already stored and the
  plan is unchanged, reconciling MUST NOT persist tabs, MUST NOT signal
  that tabs are about to change, and MUST NOT signal that tabs changed.
- **unchanged-plan-still-signals-checkout-change**: On that same
  unchanged-plan path, reconciling MUST signal that tab items need
  refreshing if and only if the checkout list actually changed from
  before, and MUST NOT signal it otherwise.
- **changed-plan-writes-and-signals-in-order**: When no tabs were stored,
  or the plan is not unchanged, reconciling MUST signal that tabs are
  about to change, then persist the new tabs, then signal that tabs
  changed, in that order.
- **default-enabled-edge**: Reconciling MUST use the previously stored
  enabled edges, or the single top edge when nothing was stored, as the
  enabled-edges list for any newly built tab record.
- **new-checkout-tabs-copy-arrangement-or-blueprint**: For every checkout
  being added, reconciling MUST build its tab records from a blueprint that
  reuses the existing tab arrangement (with fresh identifiers) when one can
  be derived from the tabs being kept, and MUST otherwise fall back to the
  project's default layout blueprint.
- **active-tab-falls-back-to-first**: Reconciling MUST set the active tab
  to the tab whose id equals the previously stored active tab id, and MUST
  fall back to the first tab in the list when no tab matches.
- **checkouts-from-worktrees**: On a successful read of the repository's
  worktrees, reading checkouts MUST convert the result into checkout
  values — which excludes every bare worktree entry — and MUST return a
  single synthetic checkout for the project's own directory, with no
  branch and marked as main, when that conversion yields zero checkouts.
- **checkouts-ordered-main-first-then-git-order**: Reading checkouts MUST
  order a non-empty result as every main checkout followed by every
  non-main checkout, each half preserving the order the worktree read
  returned it in, and MUST use a stability-preserving partition rather
  than a general-purpose sort to do so, since a general sort is not
  guaranteed to preserve the original relative order of equal elements.
- **worktree-read-failure-keeps-last-known**: When reading the
  repository's worktrees fails, reading checkouts MUST log the failure —
  naming the directory but never the git output — and MUST return the
  previous checkout list unchanged when it is non-empty, or the single
  synthetic checkout described in **checkouts-from-worktrees** when it is
  empty.
- **branch-controllers-reused-by-directory**: Synchronizing branch
  controllers MUST reuse an existing branch controller for any checkout
  whose directory matches an existing entry's key directory, even when the
  checkout's branch differs from that key.
- **branch-controllers-created-with-injected-collaborators**: For a
  checkout with no existing controller, synchronizing branch controllers
  MUST construct a new branch controller with this controller's own git
  client and with the workspace's status provider for that checkout's
  directory, and MUST register every one of that new controller's commands
  with the command registry.
- **branch-controllers-dropped-with-their-commands**: Synchronizing branch
  controllers MUST unregister the commands of every existing branch
  controller whose checkout directory is absent from the new checkout set,
  before replacing the branch-controller map with the newly built one.
- **unregister-mirrors-register**: Unregistering a branch controller's
  commands MUST unregister exactly the ids in that controller's current
  command set, no more and no fewer.
- **tab-item-resolves-directory-then-branch-controller**: Answering a
  tab-item request MUST resolve the tab record's working directory
  (falling back to the project's own directory when the record has none)
  with symlinks resolved, MUST return a plain title when no branch
  controller is found for it, and MUST otherwise return a hosted pane from
  that branch controller.
- **persist-failure-signal**: Persisting tabs catches a save failure, logs
  it, and returns nothing; reconciling signals that tabs changed
  unconditionally right after that call, so the window is told a new tab
  set was written even when the underlying write failed — the failure
  reaches only the log.
- **branch-refresh-close-race**: The serialized reconcile operation's
  per-branch-controller refresh loop does not re-check the closed flag
  between iterations, so marking the project closed partway through that
  loop lets it keep running a branch controller's refresh — and its git
  subprocess — for a controller whose commands were already unregistered;
  the extra refresh has no remaining observer.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

