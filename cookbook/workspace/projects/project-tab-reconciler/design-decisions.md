
**Decision**: A stored record is dropped only when its directory is both
gone (not a checkout, not present on disk) and its volume is currently
mounted.
**Rationale**: The doc comment on `plan(...)` states the cost of getting this
wrong directly: dropping a record "deletes the tab, its layout tree and its
remembered pane state for good," so "an unplugged drive or a dismounted
share must not cost the user a tab they can never get back"
(`ProjectTabReconciler.swift`).
**Approved**: pending

**Decision**: `projectDirectory` and each stored record's effective
directory are resolved with `resolvingSymlinksInPath()`, not merely
standardized, before any comparison.
**Rationale**: The doc comment gives the concrete failure this prevents: a
checkout's directory comes from `git worktree list` (already resolved) while
a stored record's comes from whatever the window was originally opened
with, so an unresolved symlink on either side turns a real match into a
miss and adds a duplicate tab group for a checkout that already has one
(`ProjectTabReconciler.swift`; verified by
`testARecordReachingACheckoutThroughASymlinkIsStillTheSameTab`).
**Approved**: pending

**Decision**: `makeRecords(...)` takes `blueprint` as a factory
(`() -> LayoutNode`), invoked once per enabled edge, rather than a single
`LayoutNode` value shared across every returned record.
**Rationale**: The doc comment ties this directly to a database constraint:
`layout_nodes.id` is a `TEXT PRIMARY KEY`, and `saveTabs` inserts one
member's `root` per call inside a single transaction, so members sharing one
`LayoutNode` value would share one node id, the second insert would violate
the primary key, and the whole save would roll back
(`ProjectTabReconciler.swift`; verified by
`testMakeRecordsGivesEachEdgeMemberADistinctRootNodeID`).
**Approved**: pending

**Decision**: `arrangement(of:activeTabID:)` falls back to `tabs.first` when
`activeTabID` names no element of `tabs`, rather than returning `nil`
whenever the id lookup misses.
**Rationale**: The doc comment states why the fallback must be deterministic
rather than absent: "a reconcile and the window that follows it" must
"decide the same way twice, or [they] disagree about the shape a new tab
should have" — the fallback covers a tab dropped along with its directory,
or a project that never recorded an active tab at all
(`ProjectTabReconciler.swift`).
**Approved**: pending

**Decision**: `volumeIsMounted(for:projectDirectory:)` treats `/Volumes`
itself as never mounted, and otherwise compares the volume of `directory`'s
deepest existing ancestor against the volume of `projectDirectory`'s.
**Rationale**: The doc comment explains what walking to the deepest existing
ancestor distinguishes: a mount point with nothing mounted on it, a
directory on a different but still-reachable volume, and a directory on the
same volume the project lives on — and walking `projectDirectory` the same
way keeps the comparison meaningful even when the project's own directory no
longer exists (`ProjectTabReconciler.swift`).
**Approved**: pending

**Decision**: A failed volume-identity query is treated as "no volume", so two failed lookups compare equal and the directory is reported mounted (`volume-lookup-failure-handling`).
**Rationale**: The source's volume lookup is a `try?` over the resource-values call, giving the same absent result for an error as for no volume, and the mount check compares the two results for equality. Closing it needs a stated fallback for a failed lookup (for example, treat as not determinable and keep the record) or evidence that the query never fails for a path the existing-ancestor walk already confirmed exists.
**Approved**: pending

