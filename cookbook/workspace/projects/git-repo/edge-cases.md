
- **Null and empty input**: An empty `path` is accepted unchanged by every
  constructor that takes it and is forwarded verbatim into the directory
  URL, the default-name derivation, and the leaf-name derivation, each of
  which builds a file URL from it; an empty or relative string resolves
  relative to the process's current working directory rather than failing
  construction, so an empty `path` never fails construction but the
  resulting URL/name describe wherever the process happens to be running,
  not a repository (MUST — see `git-repo-path-absoluteness`). An empty
  string for `remote` is a distinct value from no value at all; neither
  type normalizes the two together (MUST).
- **Boundary values**: A scan summary with only `removed` set above zero
  reports `found == 0` while the summary text still lists the removals, so
  a project count of zero can appear alongside a non-empty list of changes
  (MUST, see `scan-summary-found-excludes-removed`,
  git-client-projects-git-repo-006). The summary text's singular/plural
  boundary is exactly `found == 1`; both `0` and every value `2` and above
  pluralize to "projects" (MUST, `scan-summary-text-headline-pluralization`).
- **Concurrent access**: All three types are plain value types with no
  shared mutable reference state, no lock, and no thread- or task-based
  isolation of their own; every read or write operates on the caller's own
  copy, so concurrent access to independently-held instances from multiple
  threads cannot race (MUST, see `value-type-concurrency-safety`). This
  component defines no singleton, shared mutable global, or other
  ambiently-shared instance for concurrent callers to contend over.
- **Error states**: No constructor, and no derived value (the directory
  URL, the default-name derivation, the leaf-name derivation, `found`, the
  summary text), can fail or signal an error; this component calls no
  network, database, or file-system operation of its own, so it has no
  error path to define (MUST NOT be conflated with the git client's or the
  project database's error handling, which are separate components with
  their own sources).
- **Offline or disconnected state**: Not applicable — nothing in this
  component makes a network call or depends on connectivity; `remote` only
  stores a URL string another component already read out of
  `.git/config`.
- **Missing file or unreachable directory**: A `path` naming a directory
  that no longer exists on disk, or that never held a `.git` directory, is
  not detected by anything in this component — the directory URL, the
  default-name derivation, and the leaf-name derivation derive their
  result from the string alone, and none checks the filesystem for
  existence (MUST).
- **Cancellation and timeouts**: Not applicable — every operation in this
  component (construction, the directory URL, the default-name
  derivation, the leaf-name derivation, `found`, the summary text) is a
  synchronous, non-blocking computation over in-memory values; none is
  asynchronous, none spawns a subprocess, and none has anything to cancel
  or time out.

