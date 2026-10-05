
**Decision**: On Apple platforms, resolve every root's symlinks
(`resolvingSymlinksInPath()`) before storing or comparing it, in
`FileBrowserDirectories`, rather than comparing paths as given.
**Rationale**: the source's own header comment explains that the same folder
can reach this object twice under two different literal paths — once as a
checkout directory git has already resolved, once as a path the user picked
that nothing resolved — and a lexical comparison would treat those as two
different roots.
**Approved**: pending.

**Decision**: `replaceAdditional(with:)` never invokes `onChange`, unlike
`add(_:)`/`remove(_:)`.
**Rationale**: this method exists for a host to tell the object "the roots
changed somewhere else" — a project window mirroring another pane's edit to
the same shared list — and re-raising `onChange` here would send that
update back to the host that just made it, which would persist and fan it
out a second time.
**Approved**: pending.

**Decision**: `FileTreeManager.apply(_:)` overwrites `gitStatus` on every node
in the tree on every applied result, including clearing nodes with no
current entry, rather than only patching the paths a diff says changed.
**Rationale**: `GitStatus` itself carries no "what changed since last time"
information — only the full current map of file/directory statuses — so a
full re-apply is the only way to correctly clear a status for a file that
was modified and is now clean again.
**Approved**: pending.

**Decision**: `apply(_:)` treats `GitStatusRefreshResult.unavailable` as "do
nothing" rather than "clear every badge."
**Rationale**: an empty status and a failed git invocation are
indistinguishable once badges are cleared from them, and clearing on failure
would repaint an entire dirty tree as clean whenever git is misconfigured,
times out, or a request is cancelled — the source's own comment on
`GitStatusRefreshResult` calls this out directly.
**Approved**: pending.

**Decision**: A git status result that arrives before the tree has a root node is discarded and not re-applied when the root later appears.
**Rationale**: `FileTreeManager.apply(_:)` returns early when `rootNode` is nil and nothing caches the last `GitStatusRefreshResult`, while `loadInitial()` starts the sync and the git refresh independently. Closing it would take caching the most recent result and re-applying it when `rootNode` first becomes non-nil, or confirmation that an ordering guarantee makes the case unreachable; the change-triggered debounced refresh heals it only once watching has started.
**Approved**: pending

**Decision**: Overlapping full directory syncs are not serialized; whichever background read finishes last wins.
**Rationale**: `DirectoryWatchCoordinator.fullSync()` snapshots `ignorePatterns` at call time, reads on a background queue and merges on the main queue with no sequence number or in-flight guard, so a second call from `updateIgnorePatterns` or a repeated `loadInitial()` can be overtaken by an older read. Closing it would take a sequence number per run with a stale run's merge discarded, or confirmation that the two are never called close enough together for the order to matter.
**Approved**: pending

