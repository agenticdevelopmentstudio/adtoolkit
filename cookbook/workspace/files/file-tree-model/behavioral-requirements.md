
- **config-value-type**: The configuration value MUST be an immutable value
  type safe to share across concurrent contexts, and all three of its
  fields (`packageExtensions`, `packageDisplayNames`,
  `customMappingsDefaultsKey`) MUST be fixed at construction, so a
  configuration value MUST NOT be mutated after construction — a caller
  that needs different values MUST construct a new configuration value.
- **config-package-extensions-default**: Construction MUST default
  `packageExtensions` to an empty set when the caller supplies none.
- **config-package-display-names-default**: Construction MUST default
  `packageDisplayNames` to an empty mapping when the caller supplies none.
- **config-custom-mappings-key-default**: Construction MUST default
  `customMappingsDefaultsKey` to the literal
  `"AgenticFileBrowser.customMappings"` when the caller supplies none.
- **config-default-static-instance**: A well-known default configuration
  value MUST exist, equal to a configuration value constructed with all
  three defaults above.
- **node-identity-by-path**: A node's identity (`id`) MUST be set to its
  full filesystem path — never a generated identifier or any other derived
  value.
- **node-display-name**: A node's display name (`name`) MUST be set to the
  final component of its filesystem path.
- **node-directory-flag-trusted**: Node construction MUST accept the
  `isDirectory` flag exactly as the caller supplies it and MUST NOT verify
  it against the file system at construction time; a caller-supplied
  `isDirectory` value that disagrees with what is actually on disk is not
  detected or corrected.
- **node-package-detection**: A node's `isPackage` MUST be `true` if and
  only if the configured `packageExtensions` contains the node's path
  extension (a case-sensitive set-membership test), regardless of the
  node's `isDirectory` value.
- **node-attribute-read-tolerant**: Node construction MUST read `fileSize`
  and `modificationDate` via a best-effort file-attribute lookup, and MUST
  set both to `nil` — raising no error and logging nothing — when that
  lookup fails (for example a permission-denied or already-deleted file) or
  when the corresponding attribute is absent or not of the expected type.
- **node-file-size-directories-nil**: A node's `fileSize` MUST always be
  `nil` for a node whose `isDirectory` is `true`, independent of whether
  directory size attributes could be read.
- **node-children-shape-file-or-package**: A node's `children` MUST be
  `nil` for any node whose `isDirectory` is `false` or whose `isPackage` is
  `true`.
- **node-children-shape-unopened-directory**: Node construction MUST set
  `children` to an empty array — not `nil` — for a directory node (not a
  package) constructed without eagerly loading its children, so that an
  unopened, expandable directory is distinguishable from a leaf.
- **node-children-shape-eager-directory**: Node construction MUST set
  `children` directly to the result of the one-level directory read
  operation for a directory node (not a package) constructed to eagerly
  load its children, including leaving `children` as an empty array — not
  `nil` — when that directory turns out to have no visible entries; this
  diverges from the lazy children-load operation's empty-to-`nil`
  conversion (see **node-load-children-if-needed-empty-collapse**).
- **node-children-loaded-flag-eager**: A node's `childrenLoaded` MUST be
  `true` immediately when it is constructed with its children eagerly
  loaded, and MUST remain `false` when constructed without eager loading.
- **node-load-children-if-needed-guard**: The lazy children-load operation
  MUST return immediately, performing no file-system access, when
  `isDirectory` is `false`, when `isPackage` is `true`, or when
  `childrenLoaded` is already `true`.
- **node-load-children-if-needed-flag-before-read**: The lazy children-load
  operation MUST set `childrenLoaded = true` before dispatching its
  background read, not after the read completes, so that two calls to it on
  the same node in quick succession MUST result in at most one background
  read of that directory.
- **node-load-children-if-needed-background-queue**: The lazy children-load
  operation MUST perform its directory read, via the one-level directory
  read operation, on a background thread, never on the calling thread (see
  Platform Notes for the mechanism used on Apple platforms).
- **node-load-children-if-needed-empty-collapse**: The lazy children-load
  operation MUST assign the freshly-read result to `children` as `nil` when
  the read returns an empty array, and as the array itself otherwise — it
  MUST NOT leave `children` as a non-nil empty array.
- **node-load-children-if-needed-safe-publish**: The lazy children-load
  operation MUST publish the updated `children` value back on the UI
  thread, and MUST silently skip that assignment if the node has already
  been torn down before the background read completes.
- **node-load-children-if-needed-ui-thread-only**: The lazy children-load
  operation MUST be usable only on the UI thread, so every call to it MUST
  originate there (see Platform Notes for the mechanism used on Apple
  platforms).
- **node-should-ignore-glob-match**: The ignore-pattern check MUST return
  `true` if and only if the filename matches at least one pattern in
  `patterns` via shell-style glob matching, and MUST return `false` when
  `patterns` is empty.
- **node-load-children-ds-store-exclusion**: The one-level directory read
  operation MUST unconditionally exclude any entry named exactly
  `.DS_Store`, independent of `ignorePatterns`.
- **node-load-children-hidden-files-included**: The one-level directory
  read operation MUST NOT exclude hidden entries by default, so dotfiles
  other than `.DS_Store` (for example `.claude`, `.git`, `.gitignore`) MUST
  be included unless a caller-supplied `ignorePatterns` entry matches them.
- **node-load-children-read-failure-empty**: The one-level directory read
  operation MUST return an empty array, raising or logging no error, when
  reading the directory's contents fails.
- **node-load-children-directory-detection-fallback**: The one-level
  directory read operation MUST treat a child whose directory-type resource
  value cannot be read as a file (`isDirectory: false`), never as a
  directory.
- **node-load-children-recursion-depth**: The one-level directory read
  operation MUST construct every child without eagerly loading its own
  children, so one call MUST read exactly one directory level and MUST NOT
  recurse into subdirectories.
- **node-load-children-sort-order**: The one-level directory read operation
  MUST sort its result with every directory node before every file node,
  and MUST sort nodes of the same kind by `name` using a locale-aware,
  case-insensitive comparison in ascending order.
- **node-merge-identity-preservation**: The merge operation MUST, for every
  node in the fresh set whose `id` also appears among the node's current
  `children`, keep the pre-existing node instance (by reference) in the
  result rather than the corresponding instance from the fresh set.
- **node-merge-addition**: The merge operation MUST include, as the fresh
  instance itself, any node in the fresh set whose `id` does not appear in
  the current `children`.
- **node-merge-deletion**: The merge operation MUST drop from the result
  any existing child whose `id` does not appear in the fresh set.
- **node-merge-order-follows-fresh**: The merge operation MUST order its
  result according to the fresh set's order, not the previous `children`'s
  order.
- **node-equality-by-id-only**: Node equality MUST compare only `id` (the
  filesystem path); it MUST NOT consider `children`, `gitStatus`,
  `fileSize`, `modificationDate`, or any other stored property.
- **node-hash-by-id-only**: A node's hash MUST combine only `id` into the
  hash value.
- **node-git-status-external**: A node's `gitStatus` MUST be a public,
  settable property that none of this model's own operations ever assigns;
  it exists purely as a hook a caller outside this model sets.
- **node-icon-package**: A node's icon identifier MUST resolve to the
  package icon whenever `isPackage` is `true`, regardless of `isDirectory`.
- **node-icon-directory-special-names**: A node's icon identifier MUST
  resolve to the AI-assistant-directory icon for a directory named exactly
  `.claude`, the version-control-directory icon for one named exactly
  `.git`, the source-directory icon for one named `Sources`, `Source`, or
  `src`, and the test-directory icon for one named `Tests`, `test`, or
  `tests`.
- **node-icon-directory-dotfile-default**: A node's icon identifier MUST
  resolve to the hidden-configuration-directory icon for any other
  directory whose name starts with `"."`, and to the generic directory icon
  for every remaining directory.
- **node-icon-file-custom-mapping-priority**: A node's icon identifier for
  a file MUST consult the custom file-type mapping table, keyed on the
  lowercased path extension, before any other icon source, and MUST use
  that mapping's own icon identifier when one is found for a non-empty
  extension.
- **node-icon-file-builtin-fallback**: A node's icon identifier for a file
  with no custom mapping MUST use the platform's built-in icon lookup,
  keyed on the lowercased path extension, and MUST fall back to the
  generic document icon when that also returns nothing.
- **node-max-display-width-formula**: The maximum-display-width calculation
  MUST compute a node's own width as `baseWidth + (depth * indentPerLevel) +
  (name.count * characterWidth)`, using the defaults `characterWidth: 7.5`,
  `indentPerLevel: 20.0`, `baseWidth: 70.0` when the caller supplies none.
- **node-max-display-width-recursion**: The maximum-display-width
  calculation MUST return its own width unchanged when `children` is `nil`,
  and otherwise MUST return the greater of its own width and the maximum
  width returned by recursing into each child one level deeper.
- **node-max-display-width-unmaterialized-children**: The
  maximum-display-width calculation MUST compute its result only from
  nodes already materialized in memory; an unopened directory
  (`children == []`) MUST contribute no width from its own on-disk
  descendants, since none has been read yet.
- **watcher-caller-must-serialize-access**: The watcher MUST be safe to
  pass across concurrent contexts without the platform independently
  verifying its internal thread safety; callers are trusted to serialize
  their own access to start/stop.
- **watcher-exclusion-prefix-match**: The exclusion check MUST return
  `true` for a path if and only if the path equals a prefix in `prefixes`
  exactly, or starts with that prefix followed by `"/"`; it MUST NOT use a
  bare prefix match without that separator.
- **watcher-start-idempotent**: Start MUST do nothing — create no new
  stream, install no new callback — when the watcher already has a live
  stream.
- **watcher-create-failure-retryable**: Start MUST log an error and
  return, leaving the watcher with no live stream, when native
  stream creation fails; because no stream is left live, a later call to
  start MUST attempt creation again.
- **watcher-callback-path-filtering**: The change-notification callback
  MUST filter the reported paths through the exclusion check against
  `excludedPrefixes` before invoking the handler, and MUST NOT invoke the
  handler at all when every reported path is excluded.
- **watcher-callback-main-thread-dispatch**: The change-notification
  callback MUST invoke the handler on the UI thread, regardless of which
  thread the underlying notification mechanism itself delivered the event
  on.
- **watcher-stream-configuration**: Start MUST create the change-notification
  stream to report future events only (no historical replay), with a
  latency of `0.5` seconds, configured for per-file-level event granularity
  (see Platform Notes for the exact mechanism used on Apple platforms).
- **watcher-stop-teardown**: Stop MUST tear down the current stream (stop
  it, invalidate it, and release its resources), then clear the watcher's
  stream reference; it MUST do nothing when there is no live stream.
- **watcher-deinit-safety-net**: The watcher MUST tear down its stream when
  it is torn down, so a watcher discarded without an explicit stop call
  MUST still tear down its underlying change-notification stream.
- **coordinator-fixed-construction-config**: The coordinator's `rootURL`,
  `excludedPrefixes`, and `config` MUST be set once at construction and
  MUST NOT change afterward; the coordinator MUST be usable only on the UI
  thread (see Platform Notes for the mechanism used on Apple platforms).
- **coordinator-ignore-patterns-mutable**: `ignorePatterns` MUST be a
  public, mutable property that a caller MAY change at any time after
  construction, independently of `rootURL`, `excludedPrefixes`, or `config`.
- **coordinator-full-sync-one-level**: A full sync MUST read only the root
  directory's own immediate entries (via an eager node construction); it
  MUST NOT recursively read any directory below the root.
- **coordinator-full-sync-background-io**: A full sync MUST perform its
  directory read on a background thread, and MUST set `isSyncing = true`
  before dispatching that read and `isSyncing = false` only after the
  result has been applied on the UI thread.
- **coordinator-full-sync-merge-vs-replace**: A full sync MUST call the
  merge operation on the current root node — keeping that root node
  instance and reusing already-read descendant node instances — when a
  root node already exists and its location equals `rootURL`; it MUST
  replace the root node outright with the freshly-built tree only when no
  root node exists yet, or the existing one's location differs from
  `rootURL`.
- **coordinator-full-sync-completion-signal**: A full sync MUST invoke the
  registered change callback and log an info message naming the root
  directory's own name, on the UI thread, only after `isSyncing` has been
  set back to `false`.
- **coordinator-start-watching-registration**: Start watching MUST store
  the supplied closure as the registered change callback, construct a
  watcher for `rootURL` and `excludedPrefixes`, and start it; its
  change-handling closure MUST re-enter the UI thread before calling the
  change-handling routine.
- **coordinator-stop-watching-teardown**: Stop watching MUST stop the
  current watcher and clear the coordinator's stored watcher reference.
- **coordinator-handle-changes-pre-sync-guard**: The change-handling
  routine MUST return immediately, without touching `isSyncing`, when the
  root node is still `nil` — a change delivered before the first full sync
  has published a tree is already covered by that pending sync.
- **coordinator-handle-changes-affected-directories**: The change-handling
  routine MUST compute the set of affected directories as the distinct
  parent directories of every changed path.
- **coordinator-handle-changes-index-scope**: The change-handling routine
  MUST build its path-to-node index by walking only nodes already
  materialized under the root node — recursing solely through non-`nil`
  `children` arrays — and MUST drop an affected directory from the update
  set entirely when no directory node for it exists in that index; a
  change reported for a directory that has never been materialized in the
  tree MUST produce no update and no error.
- **coordinator-handle-changes-per-directory-reload**: For each affected
  directory that does have a matching node, the change-handling routine
  MUST re-read that one directory level via the one-level directory read
  operation on a background thread, then apply the result with the merge
  operation on the UI thread.
- **coordinator-handle-changes-completion-signal**: The change-handling
  routine MUST set `isSyncing = false` and invoke the registered change
  callback on the UI thread only after every affected directory's merge
  has been applied.
- **concurrent-sync-reentrancy**: Neither a full sync nor the
  change-handling routine guards against being invoked again while a previous
  invocation's background read is still in flight: both set `isSyncing = true`
  unconditionally rather than checking it first, unlike the lazy children-load
  operation's explicit set-the-loaded-flag-before-dispatch guard for the
  analogous per-node race. Two overlapping calls therefore each dispatch their
  own background read and apply the merge operation on the UI thread in
  whichever order their background work finishes, not the order the calls (or
  the underlying file-system events) occurred in (see the pending design
  decision on overlapping syncs).

