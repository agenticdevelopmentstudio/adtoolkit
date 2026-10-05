
**Decision**: A `.git` entry's mere existence — not its being a directory,
not its containing `HEAD` — is `repositoryExists(atPath:)`'s whole test,
even though the file's own scanner sibling (`GitRepoScanner.isGitDirectory(_:)`)
applies both of those stricter checks.
**Rationale**: The doc comment states it directly: "`.git` is a directory in
an ordinary checkout and a file in a worktree or a submodule, so its
existence is the whole test" (`ProjectReconciler.swift`) —
`repositoryExists` only needs to tell "still something here" from "gone,"
not to classify what kind of git artifact is present the way the scanner's
stricter detection does when deciding whether to report a new project.
**Approved**: pending

**Decision**: `isStillARepository` is a parameter injected into `plan(...)`
with a default of `ProjectReconciler.repositoryExists`, rather than `plan`
calling `repositoryExists` directly by name.
**Rationale**: The doc comment ties this to `dependency-injection`
explicitly: it keeps "the reconciler ... pure and testable without a
filesystem" (`ProjectReconciler.swift`), which is exactly how
every test in `ProjectReconcilerTests.swift` exercises the skip-versus-delete
boundary without touching disk.
**Approved**: pending

**Decision**: The move pass matches by remote first and only falls back to
directory-name equality when both sides have no remote to compare.
**Rationale**: The doc comment gives the reasoning for the ordering (two
checkouts of the same remote are "the same project moved, in the
overwhelming case," `ProjectReconciler.swift`) and for the name
fallback's narrower condition: "a name is only evidence when there is no
remote on either side to disagree about," since two unrelated directories
can share a leaf name and re-pointing one at the other would hand its
settings to a stranger (`ProjectReconciler.swift`).
**Approved**: pending

**Decision**: A move candidate must be unique or the row is deleted instead
of guessed at.
**Rationale**: The doc comment states the cost of guessing wrong directly:
"a guess here silently re-points a project's settings at the wrong folder"
(`ProjectReconciler.swift`), which the ambiguous-match test
confirms produces two fresh inserts and one deletion rather than one lucky
guess.
**Approved**: pending

**Decision**: A row whose path the scan did not report, but which
`isStillARepository` says is still a repository, is left in place — neither
moved nor deleted — rather than treated as absent.
**Rationale**: The doc comment distinguishes "not reported" from "lost":
such a row might be missing only because "the user added a skip pattern, a
parent directory turned unreadable, [or] a scan root moved," and deleting on
that evidence "cascades the project's settings, layout, tabs, pane state and
window frame away with no undo" (`ProjectReconciler.swift`). The
same comment accepts the opposite cost for a genuinely absent path — "a
project on an unmounted volume is forgotten and comes back as new" — as a deliberate, asymmetric trade-off rather than an oversight.
**Approved**: pending

**Decision**: The move pass runs, and claims its matched paths, before the
insert pass considers any scanned repository new.
**Rationale**: The doc comment states the ordering constraint plainly: "a
moved repository must claim its new path before the adoption pass below
turns that same path into a brand-new project" (`ProjectReconciler.swift`) — reversing the order would let a legitimately moved
repository lose its identity, settings, and layout to a fresh row.
**Approved**: pending

**Decision**: `summary.unchanged` is incremented for every exact-path match,
even one that also produced a write to `updates` for a changed remote.
**Rationale**: Not stated directly in a doc comment; reading the code path,
`summary.unchanged` answers "was this row still the same repository at the
same path" while `updates` answers "did any field on it need correcting" —
two different questions the source keeps separate rather than conflating,
matching the same pattern the `git-client-projects-git-repo` recipe records
for `ProjectScanSummary`'s other counts (`unchanged` never appearing in
`summaryText`'s parts list, `skipped` displayed as "not scanned").
**Approved**: pending

**Decision**: Scanned entries sharing one path are not deduplicated before matching: the plan operation treats each independently, so overlapping scan roots can yield duplicate updates for one record or duplicate inserts for one directory (`duplicate-scanned-path-handling`).
**Rationale**: The source builds a path-keyed lookup of existing records only and iterates every scanned entry, and the directory scanner accumulates multi-root results into one array without deduplicating. Closing it means a documented uniqueness precondition on the scanned input or deduplication by path at the start of the plan operation.
**Approved**: pending

