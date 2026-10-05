
- **Empty or default exclusion/ignore lists.** `excludedPrefixes: []` and
  `ignorePatterns: []` MUST leave the watcher watching everything under the
  root and the tree hiding nothing beyond the hardcoded `.DS_Store`
  exclusion (`watcher-exclusion-prefix-match`, `node-load-children-ds-store-exclusion`).
- **Genuinely empty, readable directory.** A directory with zero visible
  entries MUST read as `[]` from `loadChildren`, and the caller-visible
  `children` MUST then be `nil` when read lazily via
  `loadChildrenIfNeeded()` but MUST remain a non-nil `[]` when read eagerly
  through `init(loadChildren: true)` — the two paths intentionally diverge
  (`node-load-children-if-needed-empty-collapse`,
  `node-children-shape-eager-directory`).
- **Directory with a very large number of entries.** The one-level
  directory read operation MUST read and materialize an entire directory
  level in one call, with no pagination, batching, or entry-count limit; a
  directory with tens of thousands of entries is read in full on first
  expansion.
- **Very deep, fully-loaded tree.** The maximum-display-width calculation's
  recursion has no explicit depth cap; it MUST complete via one recursive
  step per already-loaded tree level, so its safety against unbounded
  recursion depends entirely on how many levels a caller has actually
  opened, not on any limit the source imposes
  (`node-max-display-width-recursion`).
- **Concurrent expansion requests on the same node.** Two near-simultaneous
  calls to the lazy children-load operation on the same directory node MUST
  result in exactly one background read, because `childrenLoaded` is set to
  `true` synchronously before the first call ever dispatches
  (`node-load-children-if-needed-flag-before-read`).
- **Overlapping syncs or change batches.** A full sync and the
  change-handling routine MUST NOT be assumed serialized against themselves
  or each other — see `concurrent-sync-reentrancy` in
  Behavioral Requirements and its pending design decision.
- **Changes coalesced within the watcher's latency window.** Multiple
  filesystem changes occurring within the watcher's configured
  `0.5`-second latency MUST be delivered to the coordinator as a single
  batch of changed paths, not as separate callbacks
  (`watcher-stream-configuration`).
- **Native stream-creation failure.** Start MUST log an error and leave
  the coordinator with no live watcher rather than crashing; the root
  directory continues to be sync-able via a full sync, and a later call to
  start MUST retry creation (`watcher-create-failure-retryable`).
- **Permission-denied directory.** A directory whose contents cannot be
  read (for example, permission denied) MUST be rendered identically to a
  genuinely empty directory, because the one-level directory read operation
  swallows a read failure into an empty array before it is visible to any
  caller — the same swallowing this model's own consumer, the file tree
  view, already treats as a fact rather than a distinct error state
  (`node-load-children-read-failure-empty`).
- **File deleted between listing and attribute read.** A best-effort
  attribute lookup failing on a since-deleted file MUST result in
  `fileSize == nil` and `modificationDate == nil` for that node, with no
  error raised (`node-attribute-read-tolerant`).
- **Change reported for a directory deleted before its reload runs.** When
  the change-handling routine's background reload targets a directory that
  has since been deleted, the one-level directory read operation MUST
  return `[]` for it (the same swallowed-failure path above), and the
  subsequent merge with an empty fresh set MUST drop every one of that
  node's previously-tracked children — the node itself is not removed from
  its own parent until that parent's own next reload notices it is gone.
- **No cancellation or timeout.** None of the full sync's, the
  change-handling routine's, or the lazy children-load operation's
  dispatched background work exposes a cancellation token or timeout; once
  a background read has started, that read MUST run to completion.
- **Offline or disconnected state.** Not applicable: this model operates on
  the local file system and local change notifications only; none of it
  makes a network call, so there is no connectivity-loss behavior to
  define.

