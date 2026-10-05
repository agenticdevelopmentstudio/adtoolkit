
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Notes: separation-of-concerns passes because `GitRepo.swift` holds only data
shape and trivial, filesystem-free derived accessors (`url`, `defaultName`,
`leafName`, `found`, `summaryText`); scanning the disk lives in
`GitRepoScanner`, matching found results against known rows lives in
`ProjectReconciler`, and persisting rows lives in `ProjectDatabase` — none of
that infrastructure or business logic leaks into this file. unit-test-coverage
is partial because `GitRepo.swift` has no dedicated test file of its own;
`GitRepoScannerTests.swift` exercises `ScannedGitRepo.leafName` incidentally and `ProjectReconcilerTests.swift` exercises
`ProjectScanSummary.summaryText` through two scenarios, but
`GitRepo.url`, `GitRepo.defaultName(forPath:)`, both types' `Equatable`
conformance, and the `removed`-excluded-from-`found` behavior have no test
anywhere in the given sources.

