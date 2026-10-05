
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | partial | Reliability |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | Performance |
| [secure-log-output](agenticdevelopercookbook://compliance/security#secure-log-output) | passed | Security |

Notes: separation-of-concerns passes because `ProjectWindowManager` owns
exactly window/controller lifecycle bookkeeping — the `controllers`/
`openOrder`/`projectControllers`/`keyObservers`/`closeObservers` tables — and
delegates every git read and tab-reconciliation decision to
`ProjectController`, every persistence read/write to `ProjectDatabase` through
`ProjectWorkspace`, and every pane/tab render decision to
`ComposableTabsWindowController`; it never reads git output or a tab record
itself. unit-test-coverage is partial because
`ProjectWindowManagerControllerTests.swift` exercises opening, reopening,
activation, key-observer refresh, adoption/fallback teardown routing, closing
mid-open-task, the two-writer debounce race, and synchronous `markClosed()`
timing — but `restorePlan`, `restoreOpenProjects`, and
`shutdownAllLanguageServices` have no test anywhere in the repository
(vectors -011 and -012 above are synthesized to describe what such tests
would assert). explicit-error-handling is partial: the two
`ProjectDatabase`-setting paths and the missing-language-factory path all log
their failure, but `openProject(_:)`'s missing-database guard gives the
caller no signal beyond that log — see
**no-database-open-failure-signal**. graceful-degradation passes because a
missing database, a missing language-service factory, and a missing-on-disk
folder at restore each fall back to a documented, reduced behavior (no
window, no completions, no reopen) rather than crashing or reopening a broken
window. state-recovery is partial because `restoreOpenProjects()` correctly
separates "never opened" from "flagged open, folder gone," but
`isWindowOpen(repoID:)` maps a genuine database read failure to the identical
`false` result as "was never open," so a transient read error at launch
silently drops a window from the restore set with only a log line to show for
it. main-thread-freedom passes because every subprocess- or database-bound
wait this file starts (`ProjectController.open()`/`refreshCheckouts()`, each
service's `shutdown()` inside the task group, `PendingTeardowns.drain()`) is
reached through `await`, releasing the main actor for the suspension.
secure-log-output passes because every log call names only a repo's UUID,
name, or path — already visible to the user in the project browser and the
window's own title — and no credential, token, or other secret is logged
anywhere in this file.

