
- **Null and empty input**: An existing list and a scanned list that are
  both empty MUST cause the plan operation to return a plan value whose
  `inserts`, `updates`, and `deletes` are all empty and whose `summary` has
  every count at its default of zero, since none of the four passes has
  anything to iterate. MUST.
  A scanned or existing `remote` of the empty string is treated as
  equivalent to an absent value for the purposes of `move-by-remote-priority`
  (the non-empty check rejects it) and for `move-by-name-fallback`'s
  eligibility check, even though the repository record and the scanned
  entry themselves store an absent value and an empty string as distinct
  values. MUST.
- **Boundary values**: A single-component relative path such as `"alpha"`
  (no leading separator) produces exactly one path component, so the
  naming rule's loop runs exactly once and either returns `"alpha"` or
  falls through to the exhausted-fallback return of the same string. MUST.
  When every possible suffix candidate — including the full path — is
  already in the taken-names set, the naming rule returns the original
  path string verbatim rather than producing a numbered or otherwise
  disambiguated name, so two calls in the same plan-operation run can only
  collide if the caller populates the taken-names set with every level of
  one candidate's own ancestry in advance; ordinary use (seeding the set
  from existing record names) does not reach this boundary in the given
  tests. MUST.
- **Concurrent access**: the plan operation, the repository-existence
  check, and the naming rule hold all of their mutable state in local
  variables, and their parameter and return types are safe to share across
  concurrent calls, so multiple concurrent calls with independent inputs
  cannot race against each other or against any state owned by the
  reconciler itself, which holds none. MUST. The repository-existence-check
  parameter carries no guarantee that a caller-supplied check is safe to
  invoke from a different execution context than the one that constructed
  it (see Platform Notes for the detail); the default
  built-in check captures nothing and is safe to call from anywhere. MUST.
- **Error states**: No part of this algorithm can throw. The
  repository-existence check's only failure surface never throws either; a
  permission-denied ancestor directory, a `.git` path that never existed,
  and a path on an unmounted volume all collapse to the same `false`
  result, which the plan operation then treats identically to "genuinely
  gone." This collapsing is exactly the intended, sole test ("its existence
  is the whole test"), not a swallowed error. MUST.
- **Offline or disconnected state**: Not applicable — nothing here makes a
  network call; its only I/O is the local filesystem existence check
  inside the repository-existence check.
- **Missing file or unreachable directory**: A missing record's `path`
  that no longer exists at all on disk (the ordinary "vanished repository"
  case) causes the repository-existence check to return `false`, so the
  record proceeds normally into the move pass and, absent a match, into
  `deletes`. MUST.
- **Cancellation and timeouts**: Not applicable — the plan operation, the
  repository-existence check, and the naming rule are all synchronous
  computations with nothing to cancel and no operation that can run long
  enough to time out.
- **Duplicate paths in the inputs**: See `duplicate-existing-path-handling`
  (a caller precondition the registry's storage layer enforces) and the
  pending decision on `duplicate-scanned-path-handling`; nothing here rejects
  or normalizes either.

