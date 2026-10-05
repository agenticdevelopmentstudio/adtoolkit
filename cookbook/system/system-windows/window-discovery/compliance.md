
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | Performance |
| [progress-indication](agenticdevelopercookbook://compliance/performance#progress-indication) | passed | Performance |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | failed | Reliability |
| [platform-permissions](agenticdevelopercookbook://compliance/platform-compliance#platform-permissions) | passed | Platform Compliance |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | partial | Privacy and Data |

separation-of-concerns passes because enumeration and focus live in the window-management engine, title parsing in the heuristic registry, permission checks in the Accessibility permission component, and the model only filters, groups, matches and sorts, with matching isolated in a pure static function. unit-test-coverage is partial: the matching tests cover matching (heuristic match, raw-title fallback, non-match, empty and `"Unknown"` projects) but nothing tests grouping, filtering, sorting, the permission gate or activation, and the engine is not injectable. explicit-error-handling is partial: focus failures are caught and logged but not surfaced to the caller, and the ordering of overlapping discoveries is undefined (the open question on overlapping-discovery-order). main-thread-freedom passes because the window list and backfill run on a background queue. progress-indication passes because `isLoading` is published from the start of discovery to the publish. graceful-degradation passes because a missing permission yields `accessibilityDenied` instead of a failure, and withheld titles are backfilled. timeout-handling fails because discovery has no timeout. platform-permissions passes because the model checks trust without prompting and prompts only from the user-initiated settings action. data-minimization passes because only title, pid, window number, name and icon are kept, in memory. no-pii-in-logs is partial because the activation log records the window title, which can contain document or project names, as public.

