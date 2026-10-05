
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | partial | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |

Notes: separation-of-concerns passes because `ProjectsCoordinator` owns
exactly the `repos` list, the scan/reconcile/persist sequencing in
`finishScan`, and command/menu registration, while delegating every
directory walk to `GitRepoScanner`, all match/insert/update/delete
arithmetic to `ProjectReconciler`, all persistence to `ProjectDatabase`,
and all window presentation to `ProjectOpening`/`ProjectChooserWindow`/
`ProjectScanProgressWindow` — its own doc comment states it knows a
project only as "a row, not a file." unit-test-coverage fails because no
test file exists anywhere in the repository for this type (no
`ProjectsCoordinatorTests.swift`), so every behavior documented above,
including the pending decisions and gaps above, is currently unverified by any
automated test. explicit-error-handling is partial because four of the six
database-touching call sites (`rename`, `openProject`, and `finishScan`'s
insert/update/delete loops) catch and log their failure, but two — the
`database.allRepos()` reads in `init`/`reload()` and `database.checkpoint()`
in `stop()` — swallow through `try?` with no log call at all (see
**database-read-failure-unsignaled**, **stop-checkpoint-failure-unsignaled**).
state-recovery is partial because `init`'s load and `reload()`'s refresh
from `database.allRepos()` are this feature's whole recovery mechanism
after a process restart, but a failed read on either path is
indistinguishable from a database that is genuinely empty — there is no
signal a caller or a future launch could use to tell the two apart.
data-integrity is partial because `finishScan`'s insert and delete loops
keep `summary`'s counts truthful to what was actually written on a caught
failure, but the update loop does not (see
**finish-scan-updates-no-decrement-on-failure**), so `lastScanSummary` can
overstate how many rows were actually updated whenever one `database.update`
call in a scan fails.

