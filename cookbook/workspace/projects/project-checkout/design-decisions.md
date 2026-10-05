
**Decision**: `init(directory:branch:isMain:)` resolves `directory` with
`resolvingSymlinksInPath()` rather than `standardizedFileURL`.
**Rationale**: The doc comment states the two sides being compared reach a
directory by different routes — `git worktree list` prints the fully
resolved path while a workspace's directory comes from the path the user
gave — so only resolving symlinks (which subsumes standardizing `.`/`..`
too) makes every `Set` lookup and dictionary key pairing them succeed
(`ProjectCheckout.swift`).
**Approved**: pending

**Decision**: `identifier` is derived only from `directory`, deliberately
excluding `branch` and `isMain`.
**Rationale**: The doc comment states the identifier is "path-derived so a
checkout keeps its identity across branch switches" — a stable value for a
checkout-namespaced command id even as the checkout's live branch changes
(`ProjectCheckout.swift`).
**Approved**: pending

**Decision**: `checkouts(from:)` drops every `GitWorktree` whose `isBare` is
`true`, and does not carry `head` or `isDetached` into the `ProjectCheckout`
values it produces.
**Rationale**: The doc comment gives the reason for the bare exclusion
directly — "bare entries have no working directory to open a tab in" — and
the projection to just `directory`, `branch`, and `isMain` reflects that
`ProjectCheckout` only needs what identifies a tab-openable location, not
the full worktree record (`ProjectCheckout.swift`).
**Approved**: pending

