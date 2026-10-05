
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |

Notes: separation-of-concerns passes because `ProjectReconciler.swift` does
exactly one thing — match scan results against known rows — and delegates
walking the filesystem to `GitRepoScanner`, persisting rows to
`ProjectDatabase`, and presenting progress to `ProjectsCoordinator` and its
progress window, none of which leaks into this file. unit-test-coverage is
partial: `ProjectReconcilerTests.swift` exercises every branch of `plan(...)`
directly (inserts, unchanged, remote updates, remote-based moves,
name-based moves, ambiguous moves, move-before-insert ordering, deletes, and
the summary counts) and `uniqueName(forPath:taken:)`'s escalation directly,
but `repositoryExists(atPath:)` is only ever exercised incidentally, as the
default `isStillARepository` argument hitting the real filesystem at
ephemeral test paths, never by a dedicated test asserting its true/false
contract against a constructed `.git` entry, and `uniqueName`'s
exhausted-fallback branch has no test at all. idempotent-operations
passes: the doc comment and `testAnUnchangedRepoProducesNoWrite`'s own name
tie the exact-path pass's "no update when nothing changed" behavior directly
to re-running a scan over an unchanged tree producing no database write.
data-integrity is partial because of the pending decision on
duplicate-scanned-path-handling: overlapping scan roots can report one
directory twice and silently produce two rows for it, with nothing in this
file detecting it. Duplicate `existing` rows are excluded by the `git_repo`
table's `UNIQUE` path constraint rather than by this file.

