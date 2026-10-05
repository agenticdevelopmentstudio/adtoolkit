
- **checkout-identity-fields**: A checkout MUST expose exactly three
  fields — `directory` (a location value), `branch` (a string, optional),
  and `isMain` (a boolean) — and no others.
- **symlink-resolved-directory**: Creating a checkout MUST set `directory`
  to the symlink-resolved form of the location the caller passed in, never
  the caller's unresolved value.
- **resolution-not-standardization**: Creating a checkout MUST resolve
  `directory` by fully resolving symlinks rather than only normalizing the
  path, so that a path reached through a symlink and the same path reached
  through the symlink's target resolve to one identical `directory` value;
  normalization of `.` and `..` segments MUST also apply, since symlink
  resolution subsumes normalization.
- **hashable-includes-all-fields**: Two checkouts MUST compare equal, and
  MUST produce the same hash, only when their `directory`, `branch`, and
  `isMain` are all equal; equality and hashing are derived from all three
  fields, with no custom override that would exclude any of them.
- **value-type-concurrency-safety**: A checkout MUST be safe to read,
  compare, hash, and pass across concurrency domains with no
  synchronization, since every field is immutable and holds only
  concurrency-safe data, and the value has no reference-typed or mutable
  state.
- **path-derived-identifier**: `identifier` MUST compute a djb2 hash over
  the UTF-8 bytes of `directory`'s path string — seeded at `5381`, updated
  per byte as `hash = (hash * 33) + byte` using wrapping (overflow-safe)
  arithmetic — and MUST render the result as a lowercase hexadecimal
  string.
- **identifier-ignores-branch-and-main-flag**: `identifier` MUST depend only
  on `directory` and MUST NOT vary with `branch` or `isMain`, so a checkout
  keeps the same `identifier` across a branch switch on the same directory.
- **display-name-prefers-branch**: `displayName` MUST return `branch` when
  it is present, and MUST return the last path component of `directory`
  when `branch` is absent.
- **bare-worktrees-excluded**: The checkout projection MUST exclude every
  worktree record whose `isBare` is `true` from its returned list, because a
  bare entry has no working directory to open a tab in.
- **checkouts-preserve-order**: The checkout projection MUST return the
  surviving, non-bare worktrees in the same relative order they appear in
  the input list.
- **checkouts-projection-is-lossy-by-design**: The checkout projection MUST
  build each checkout from only its source worktree record's `directory`,
  `branch`, and `isMain`; the source record's `head` and `isDetached` values
  MUST NOT be carried into the produced checkout in any form.

