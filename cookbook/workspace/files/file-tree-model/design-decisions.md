
- **Decision**: `fullSync()` merges into the existing `rootNode` (when its
  `url` matches) instead of always replacing it with the freshly-built tree.
  **Rationale**: Stated directly in the source's inline comment: a fresh
  root is a fresh object for every directory beneath it, so replacing it
  outright would orphan whatever the outline view had already read for a
  currently-open folder, and that folder would come back empty on the next
  redraw even though nothing about it actually changed. Re-using the nodes
  keeps identity, and with it everything already read.
  **Approved**: pending
- **Decision**: Filename exclusion is split across two independent
  mechanisms — `excludedPrefixes` (path-prefix filtering inside
  `FileSystemWatcher`'s FSEvents callback) and `ignorePatterns` (glob
  filename filtering inside `FileTreeNode.loadChildren`) — rather than one
  shared list.
  **Rationale**: Not stated in a source comment. The two operate at
  different layers with different costs: `excludedPrefixes` stops FSEvents
  from ever delivering paths under a noisy subtree (`.git`, `node_modules`)
  to `handleChanges` at all, while `ignorePatterns` only decides what a
  directory listing displays. A directory can therefore be excluded from
  live watching yet still be listable once via `loadChildren` (opening
  `.git` manually still shows its contents unless a pattern also hides it),
  and a filename hidden by `ignorePatterns` still generates FS events that
  reach `handleChanges` if its directory isn't separately excluded.
  **Approved**: pending
- **Decision**: A directory read eagerly at construction
  (`init(loadChildren: true)`) keeps `children` as a non-nil empty array
  when it turns out to be empty, while the lazy path
  (`loadChildrenIfNeeded()`) converts that same empty result to `nil`.
  **Rationale**: Not stated in a source comment for the eager path
  specifically; the lazy path's own comment explains only its half: "`nil`,
  not an empty array, for a directory that turned out to have nothing in
  it... keeping it would leave a disclosure triangle that opens onto
  nothing." The eager path has no equivalent conversion, so the two
  construction paths leave a genuinely empty, already-read directory in two
  different observable shapes depending on which path read it.
  **Approved**: pending
- **Decision**: `loadChildrenIfNeeded()` sets `childrenLoaded = true`
  synchronously, before dispatching the background read, rather than after
  the read completes.
  **Rationale**: Stated directly in the source's inline comment: "two rows
  appearing in the same frame must not both start the same enumeration."
  Setting the flag first makes a second near-simultaneous call see
  `childrenLoaded == true` and return early, guaranteeing at most one
  background read per directory per open.
  **Approved**: pending
- **Decision**: On Apple platforms, the FSEvents callback force-casts
  `eventPaths` via `unsafeBitCast(eventPaths, to: NSArray.self) as!
  [String]`, with an inline `swiftlint:disable:this force_cast` comment.
  **Rationale**: Not stated beyond the disable comment itself; the cast's
  safety depends entirely on `kFSEventStreamCreateFlagUseCFTypes` being
  passed to `FSEventStreamCreate` (`watcher-stream-configuration`), which
  guarantees `eventPaths` really is a `CFArray` of `CFString`s bridgeable to
  `NSArray`/`String`. This is accepted technical debt: if that flag were
  ever removed, the cast would crash rather than fail gracefully.
  **Approved**: pending
- **Decision**: On Apple platforms, `FileSystemWatcher.start()` logs the
  watched root path with an explicit `privacy: .public` annotation rather
  than `os.log`'s private-by-default redaction for interpolated values.
  **Rationale**: Not stated in a source comment. A locally-mounted project
  path is treated here as safe to surface in log output, which is a
  deliberate choice given `os.log` otherwise redacts interpolated strings by
  default.
  **Approved**: pending

**Decision**: Overlapping full syncs and change batches are not coalesced or serialized; the merge order is last-completion-wins.
**Rationale**: `DirectoryWatchCoordinator.fullSync()` and `handleChanges(_:)` each set `isSyncing = true`, dispatch a background read and merge on the main queue with no in-flight check or sequence number, so an older read finishing later overwrites a newer one's result. No source rationale or test exists for the current ordering; closing it would take coalescing or serializing overlapping runs, or a test showing last-completion-wins is acceptable.
**Approved**: pending

