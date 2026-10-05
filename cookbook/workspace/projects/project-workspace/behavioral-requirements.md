
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **repo-identity**: `id` MUST be computed as the repository's own id,
  `displayName` MUST be computed as the repository's own name, and
  `directoryURL` MUST be computed as the repository's own directory, on
  every access rather than cached separately.
- **repo-mutation-exposed-read-only**: The repository MUST be exposed
  read-only, so only this workspace's own update operation may change
  it; every other reader sees it as read-only.
- **update-preserves-identity**: Updating the repository MUST replace the
  stored repository with the argument only when the argument's id equals
  the stored repository's id, and MUST leave the stored repository
  unchanged and return with no other effect when the ids differ.
- **pane-number-allocation-is-monotonic**: Allocating a pane number MUST
  return the current value of an internal counter that starts at `1` and
  MUST then increment that counter, so no two calls on one workspace
  instance ever return the same number and no released number is ever
  reused.
- **cache-directory-derivation**: The cache directory MUST be computed as
  a `caches/<repository id as a UUID string>/` subdirectory of the
  directory containing the database's own file, and reading it MUST NOT
  create that directory or any of its parents on disk.
- **stored-tabs-nil-when-empty-or-absent**: Reading stored tabs MUST
  return nothing both when loading tabs from the database throws and
  when it returns a tabs list that is empty, collapsing "nothing was
  ever persisted" and "the load failed" into the same result.
- **initial-tabs-default-when-nothing-stored**: When reading stored tabs
  returns nothing, computing the initial tabs MUST return exactly one
  tab record titled `"Tab 1"` with its root set to the layout's own
  blueprint, that tab's own id as the active tab id, and a single top
  edge as the enabled edges.
- **stored-tab-trees-repaired-against-current-spec**: When tabs are
  stored, computing the initial tabs MUST rewrite every tab's root by
  reconciling it against the layout's current spec before doing anything
  else with it, so a tree built under an earlier spec that no longer
  allows one of its panes is repaired on load.
- **one-arrangement-per-project**: After that repair, computing the
  initial tabs MUST compute one shared arrangement over the repaired
  tabs and their active-tab id, and, when that computation produces one,
  MUST reshape every tab's root to match it, each tab getting its own
  fresh set of node ids.
- **stale-focused-node-cleared**: For every tab, computing the initial
  tabs MUST clear the focused node to none whenever that node's id is no
  longer present among the tab's (possibly just rewritten) root's leaf
  ids, following either rewrite above.
- **active-tab-fallback**: Computing the initial tabs MUST return the
  stored active-tab id as the active id when it names one of the
  returned tabs, and MUST otherwise fall back to the first returned
  tab's own id.
- **persist-tabs-swallows-failure**: Persisting tabs MUST save the given
  tabs, active-tab id, and enabled edges to the database, and on failure
  MUST log the error and MUST NOT throw, retry, or otherwise signal the
  failure to its caller.
- **pane-state-scoped-by-node-and-key**: Reading and writing pane state
  MUST read and write through the database's own pane-state accessors,
  scoped by this project's own repository id together with the given
  node id and key.
- **chrome-prefix-is-unenforced-convention**: A key beginning with
  `chrome.` is reserved for the pane-state store's own use; pane content
  reading or writing pane state MUST NOT use a key with that prefix, but
  the workspace performs no runtime check of this rule itself.
- **pane-state-failures-swallowed-and-logged-with-full-context**: Reading
  pane state, writing pane state, and pruning nested pane state MUST
  each catch any error the database throws, log it naming the verb, this
  project's repository id, the node id, and the key (`"*"` for pruning),
  and MUST NOT propagate it; reading pane state MUST return nothing on
  that path and writing/pruning MUST simply return.
- **pane-state-list-json-encoded**: Reading a pane-state list MUST decode
  the stored string as a JSON list of strings and MUST return an empty
  list when the key is unset, the stored string is not valid text, or
  JSON decoding fails. Writing a pane-state list MUST clear the key when
  the given list is empty, and MUST otherwise JSON-encode the list to a
  string and write it, doing nothing when either encoding step fails.
- **project-setting-scoped-by-repo**: Reading and writing a project
  setting MUST read and write through the database's own per-repository
  setting accessors, scoped to this project's own repository id, and
  MUST log and return nothing (for a read) or simply return (for a
  write) on failure rather than propagate it.
- **setting-nil-deletes-row**: Writing a project setting with no value
  MUST delete the underlying row rather than storing an empty or null
  value, so "never set" and "set back to the default" are the same
  state.
- **project-directories-load-failure-yields-empty**: Reading the
  project's extra directories MUST return an empty list and log the
  failure when loading them from the database throws, rather than
  propagate the error or return a stale cached value.
- **file-browser-directories-cached-per-resolved-primary**: The
  file-browser-directories lookup MUST resolve symlinks in its
  primary-directory argument before using it as a cache key, MUST return
  the cached value for that resolved key when one is still alive, and
  MUST otherwise construct a new value seeded with the project's extra
  directories, register the directory-change handler on it, cache it
  under the resolved key, and return it.
- **file-browser-directories-weakly-held**: The cache backing the
  file-browser-directories lookup and the git-status-provider lookup
  MUST hold its values weakly and MUST drop a key as soon as nothing
  outside the cache still holds the value stored under it, so a
  directory nothing is showing any more is forgotten rather than
  accumulated for the life of the project.
- **directory-addition-fans-out-to-every-live-sibling**: The
  directory-change handler MUST persist the merged directory list and
  then refresh every other still-live cached file-browser-directories
  value the cache currently holds (every live entry whose key is not the
  one that changed), so a directory added or removed through one
  directory's browser reaches every other open browser for the same
  project.
- **primary-is-re-added-if-stored-but-dropped**: Before persisting, the
  directory-change handler MUST re-add the changed value's own primary
  directory to the merged list when the previously stored list contained
  it but the incoming directory list does not, and MUST NOT add it
  otherwise — because a file-browser-directories value never lists its
  own primary among its additional roots.
- **git-status-provider-cached-per-resolved-directory**: The
  git-status-provider lookup MUST resolve symlinks in its directory
  argument before using it as a cache key, MUST return the cached value
  for that key when one is still alive, and MUST otherwise construct a
  new git-status provider over this project's own git client, cache it
  under the resolved key, and return it.
- **extension-workspace-roots-conformance**: The workspace MUST conform
  to the extension-workspace-roots interface, exposing its display name
  as the project's own display name and its workspace root directories
  as the project's own file-browser directories, primary first.
- **git-client-defaults-to-shared-injectable**: Construction MUST default
  the git client to the shared git client when the caller supplies none,
  and every operation that mints a per-directory object or vends git
  access (the file-browser-directories lookup, by way of caching; the
  git-status-provider lookup) MUST use this project's stored git client,
  never a client of its own.
- **layout-defaults-through-fallback-chain**: Construction MUST resolve
  an absent layout argument as the app-installed layout when one exists,
  or a placeholder-only layout otherwise.
- **stored-tabs-load-failure-signal**: reading stored tabs discards whatever error loading tabs from the database throws, with no log call and no other signal, unlike every other failing database access in this file (settings, extra directories, persisting directories or tabs, and the three pane-state operations all log on failure); a database error while loading tabs is therefore indistinguishable from a project that has never saved any (see Design Decisions).

