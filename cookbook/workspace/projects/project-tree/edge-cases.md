
- **Null and empty input**: An empty registry MUST yield empty roots
  (MUST, see `build-empty-input-yields-empty-tree`, PT-008). A repository
  path that standardizes to a string with zero `"/"`-separated components
  (for example `"/"`) makes the trail computation return an empty list,
  and building the tree silently omits that repository from the tree (see
  `project-tree-degenerate-path-dropped` — the pending decision on this behavior).
- **Boundary values**: A path exactly equal to home (not longer than it)
  is, by `trail-under-home-detection`, NOT treated as under home, so it is
  shown with its full absolute component list rather than collapsed to
  nothing (MUST). The path-standardization step's trailing-slash strip
  only fires when the path's length is greater than 1, so the
  single-character path `"/"` is left as `"/"` rather than becoming an
  empty string (MUST).
- **Concurrent access**: a tree node and the tree-building operation are
  both confined to a single execution context (MUST, see
  `confines-to-ui-thread`), and a tree node offers no cross-context
  sharing guarantee of its own (see the concurrency note in Platform
  Notes), so cross-context access must go through that confinement; this
  file defines no lock, no queue, and no other concurrency primitive of
  its own because that confinement is the only synchronization mechanism
  in play.
- **Error states**: No function in this file throws, returns an optional
  the caller must unwrap and handle, or calls anything that can fail
  (conditional-exit statements here select control flow, not error
  propagation); a repository whose path degenerates to an empty trail is
  dropped with no error path at all rather than surfacing a failure (see
  `project-tree-degenerate-path-dropped`).
- **Offline or disconnected state**: Not applicable — this file makes no
  network call and depends on no connectivity; it operates purely on the
  in-memory registry and home-directory reference passed to the build
  operation.
- **Missing file or unreachable directory**: Not applicable to this file
  itself — building the tree, computing a path's trail, and the
  path-standardization step derive every result from path strings alone
  and never check whether a repository's path exists on disk or is
  actually a directory; a path naming a location that no longer exists is
  placed in the tree exactly as if it still did.
- **Cancellation and timeouts**: Not applicable — building the tree and
  every helper it calls (trail computation, path standardization,
  recursive sort) are synchronous, non-asynchronous, in-memory
  computations over a caller-supplied list; none spawns a subprocess or a
  long-running operation that anything could cancel or that could time
  out.
- **Ordering and duplicate paths**: Two repositories whose standardized
  path is byte-for-byte identical produce exactly one tree node (MUST, see
  `build-duplicate-leaf-path-dropped`, PT-009), but a repository whose
  path equals a different repository's ancestor folder path produces two
  sibling nodes at that path — one folder, one project (see
  `project-tree-leaf-path-collision` — the pending decision on this behavior, PT-010). Which of the two repositories in the registry is
  processed first determines which node (folder or project) is created
  at a shared ancestor path first, since building the tree iterates the
  registry in the order given and never reorders it before building.

