
- **Null and empty input**: Renaming a repository with an id not present
  in the repository list MUST be a no-op — looking it up by id returns
  nothing and the guard exits before any trim or write. MUST. A new name
  that is empty, all-whitespace, or trims down to the unchanged current
  name MUST also be a no-op, performing no database write and no
  reload. MUST. A scan whose scanner reports zero repositories on disk
  MUST still run the scan-finishing step to completion; the
  reconciliation plan, given an empty found list, produces deletions for
  every currently known row that the scanner's own liveness check does
  not excuse, so an empty scan is never distinguished at this layer from
  "the disk root genuinely lost every repository" — that distinction
  belongs to the scanner and the reconciler, not this feature. MUST.
- **Boundary values**: This feature performs no truncation, pagination,
  or count-based branching on the size of the repository list or the
  found list at any point — zero, one, or many rows in the plan's
  insertions, updates, or deletions all take the identical per-row loop
  when finishing a scan. MUST.
- **Concurrent access**: A second scan call arriving while one is already
  running MUST be dropped with no work performed and no queuing for a
  later run — the guard is the entire re-entrancy policy, and the inline
  comment states this is deliberate. MUST. The scan's own background
  continuation is not tracked by any stored handle, so stopping or
  terminating racing an in-flight scan is not resolved by this feature
  at all (see **scan-task-not-tracked**); every write inside
  scan-finishing is independently caught, so such a race cannot corrupt
  the database, only leave the is-scanning flag stuck set for that run.
- **Error states**: Every database write this feature performs directly
  (the update in renaming, recording the open time in opening a project,
  and the insert/update/delete calls in scan-finishing) is caught
  individually and logged at error level without propagating. MUST. Two
  read/checkpoint paths instead swallow the error with no log call at
  all — reading all repositories in construction and reloading, and
  checkpointing in stopping — see **database-read-failure-unsignaled**
  and **stop-checkpoint-failure-unsignaled**.
- **Offline or disconnected state**: Not applicable — this feature makes
  no network call of its own. The database is a local file and the
  scanner walks the local filesystem; neither this feature nor its
  direct collaborators depend on network reachability.

