
**Decision**: `commandRegistry` is a required, non-defaulted `init`
parameter rather than an optional with an internal fallback registry.
**Rationale**: The doc comment states the reason directly: a defaulted
private registry would let a caller omit the argument and still get "a
working menu — while the palette silently lost this entire feature's
commands, with no log, no crash and nothing a test could observe." Requiring
the parameter moves that failure to compile time (`ProjectsCoordinator.swift`).
**Approved**: pending

**Decision**: A `scan()` call arriving while one is already in flight is
dropped, not queued or coalesced.
**Rationale**: The inline comment states the reasoning: "two scans of the
same disk produce the same answer, so the second is waste." No caller of
`scan()` is left waiting for a result it would receive anyway from the
scan already running (`ProjectsCoordinator.swift`).
**Approved**: pending

**Decision**: `finishScan` closes every project window slated for deletion
in one pass, completed before any row in `plan.deletes` is actually deleted.
**Rationale**: The inline comment gives the ordering constraint: a window
still open against a row after that row is deleted "is a foreign key that
no longer resolves." Closing first avoids a write from a still-open window
landing on a row that database-level cascading has already removed
(`ProjectsCoordinator.swift`).
**Approved**: pending

**Decision**: `terminate()` reaches the language-server shutdown through a
runtime cast (`opener as? ProjectWindowManager`) rather than widening
`ProjectOpening` to declare a shutdown method.
**Rationale**: The doc comment states the seam is deliberate: `ProjectOpening`
"says nothing about language servers, and widening it for this one call
would push an LSP concern into the protocol the registry is tested
against." A host that supplies a different `ProjectOpening` implementation
simply skips the shutdown call rather than being forced to implement it
(`ProjectsCoordinator.swift`).
**Approved**: pending

**Decision**: `scan(...)` reads `UserSettings.projectScanSkipPatterns` fresh
inside every call rather than caching the scanner (or the setting) at
`init` time, whenever no scanner was injected.
**Rationale**: The doc comment on `injectedScanner` states the intent:
leaving the field `nil` in the ordinary case means "editing the skip list
takes effect on the next scan rather than the next launch"
(`ProjectsCoordinator.swift`).
**Approved**: pending

**Decision**: A failed database read in construction or reload is discarded without a log call: the result falls back to an empty list on construction and to the existing list on reload (`database-read-failure-unsignaled`).
**Rationale**: The source reads through `try?` in both places, so an empty registry and a failed read look identical to callers. Closing it needs a log call, a way for the caller to detect a failed reload, or a comment stating the silence is intentional because a failed read is transient and self-correcting on the next reload.
**Approved**: pending

**Decision**: Stopping discards a checkpoint failure without any log call (`stop-checkpoint-failure-unsignaled`).
**Rationale**: The source calls the database checkpoint through `try?` on the stop path, unlike the sibling database calls that log. Closing it means a log call on the caught path matching those siblings, or a comment explaining why a failed checkpoint at shutdown needs no signal.
**Approved**: pending

