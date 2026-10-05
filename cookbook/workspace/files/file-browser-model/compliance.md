
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | passed | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |

`separation-of-concerns` passes: `FileTreeManager` only orchestrates,
delegating directory scanning/watching to `DirectoryWatchCoordinator`, git
overlay to `GitStatusProvider`, and IDE detection to `IDEDetector`, while
`FileBrowserDirectories` and `FileBrowserRestorationState` are each a single,
independent model. `unit-test-coverage` is partial: `FileBrowserRestorationStateTests`
covers `FileBrowserRestorationState` directly and `FileTreeManagerInjectedProviderTests`
covers `FileTreeManager`'s dependency-injection behavior, but no test file
exercises `FileBrowserDirectories`' `add`/`remove`/`normalize`/
`root(containing:)` methods directly, nor `FileTreeManager`'s debounce or
`apply(_:)` behavior. `explicit-error-handling` is partial: `GitStatusRefreshResult.unavailable`
is an explicit, named failure case, but the two races recorded above as pending decisions show that a dropped or superseded result currently produces no
signal of any kind. `state-recovery` passes: `FileBrowserRestorationState`
exists specifically so a host can persist and restore disclosure/selection
across a relaunch. `idempotent-operations` passes: `FileBrowserRestorationState.setExpanded`/
`setSelectedPath` and `FileBrowserDirectories.normalize`/`replaceAdditional`
all guard against reporting or reassigning when nothing actually changed.

