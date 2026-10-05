
This module is the storage floor the sync stack and the app's other stores
sit on. It has two parts:

- The bounded database wraps an underlying multi-reader, single-writer
  database connection pool (or a single shared connection for a private
  in-memory database) with two guarantees so a runaway query can never
  wedge the process: a **bulkhead** (one writer plus N readers, using
  write-ahead logging, so reads never queue behind the writer) and
  **ejection** (every read/write carries a monotonic deadline; a low-level
  statement-abort mechanism aborts any statement that passes it, surfaced
  as a deadline-exceeded error). It keeps per-lane latency and eviction
  counters exposed as a metrics snapshot, and it is reentrant, so a code
  base can keep one read/write chokepoint instead of threading a raw
  connection handle everywhere.
- The storage-location helper derives where an app keeps its files — a
  dotfolder in the home directory — from the app's declared display name,
  reduced to characters a path can hold.

Consumers include the sync store (see
[Offline Sync Client](adtoolkit://cookbook/data/sync/offline-sync-client)),
the markdown store (see [Markdown Core](adtoolkit://cookbook/adh/hub/content/markdown-store)),
and the project database (see
[Project Database](adtoolkit://cookbook/workspace/projects/project-database)),
which names its file inside the storage-location helper's directory.

