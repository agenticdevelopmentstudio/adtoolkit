
- **Null and empty input**: `branch` being absent MUST fall back
  `displayName` to the last path component of `directory` rather than
  producing an empty or placeholder string. MUST. An empty list of worktree
  records passed to the checkout projection MUST return an empty list,
  since filtering and mapping over an empty collection produce no elements.
  MUST.
- **Boundary values**: A `directory` whose path is the single-character
  root `/` MUST still produce a deterministic, non-empty hexadecimal
  `identifier`, since the djb2 loop only iterates over the path's bytes and
  has no special case for a short path. MUST.
- **Concurrent access**: A checkout MUST be readable, comparable, and
  hashable concurrently from multiple threads with no synchronization,
  because every field is immutable and `identifier`/`displayName` are pure
  computations with no shared mutable state (see
  value-type-concurrency-safety). MUST. The checkout projection has no
  shared state of its own, so concurrent calls with different worktree-record
  lists MUST NOT interfere with one another. MUST.
- **Error states**: Resolving `directory`'s symlinks is a non-error-raising
  operation, and creating a checkout has no error-handling path at all; when
  `directory` names a path that does not exist on disk, creating the
  checkout MUST NOT raise or surface an error — it stores whatever the
  resolution step returns, which is a best-effort result rather than a
  validated one. MUST (this is a fact about a non-error-raising operation,
  not a swallowed error — there is no error here to swallow).
- **Offline or disconnected state**: Not applicable — creating or projecting
  a checkout makes no network call; `directory`, `branch`, and `isMain` are
  supplied by the caller or derived from a worktree record already read
  from local disk.
- **Duplicate worktree entries**: When the worktree-record list passed to
  the checkout projection contains two entries with the same `directory`,
  the projection MUST produce two separate checkout values rather than
  deduplicating them, since it performs a strict one-to-one mapping with no
  deduplication step. MUST.

