
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | failed | Reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | Performance |
| [platform-permissions](agenticdevelopercookbook://compliance/platform-compliance#platform-permissions) | partial | Platform Compliance |
| [data-retention-policy](agenticdevelopercookbook://compliance/privacy-and-data#data-retention-policy) | partial | Privacy and Data |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | partial | Privacy and Data |

separation-of-concerns passes because the target value, each strategy, the terminal catalog, the running-apps abstraction, TTY resolution, logging and the harness each live in their own type. unit-test-coverage fails because no test file exists for any type in the package, despite `RunningAppsProvider` and `ActivationTestLog(fileURL:)` being designed for injection. explicit-error-handling is partial: AppleScript compile and runtime failures and missing TTYs are logged with detail, but two strategies report success without checking the platform call results (the open questions on ax-raise-result and front-activate-result) and file write failures are dropped by design. timeout-handling fails because neither the `ps` subprocess nor the AppleScript calls have a timeout. graceful-degradation passes because a missing Application Support directory falls back to memory-only logging and a denied accessibility permission aborts cleanly with a logged reason. main-thread-freedom passes because `runAllTests()` is documented to run off the main thread and hops to main only for the final host reactivation, though applescript-thread notes that its AppleScript calls stay on that background thread. platform-permissions is partial: accessibility trust is checked and reported before any work, but Automation permission for iTerm2 is not checked up front and only surfaces as a runtime AppleScript error. data-retention-policy is partial because the file is cleared at each run start but otherwise grows without bound and persists across launches. no-pii-in-logs is partial because the log records working-directory paths (which include the user's home directory name) and window titles in plain text on disk.

