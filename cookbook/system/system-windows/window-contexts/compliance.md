
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | passed | Reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [encryption-at-rest](agenticdevelopercookbook://compliance/privacy-and-data#encryption-at-rest) | failed | Privacy and Data |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy and Data |

`separation-of-concerns` passes: persistence is in the store, window and context logic in the `@MainActor` manager, SwiftUI publishing and user-facing messages in the model, and host branding in an injected configuration, with the window controller and matcher injected. `unit-test-coverage` is partial because `SystemWindowContextManagerTests` covers parking on attach, the no-active-context case, active-context deletion, and both load-time invalidation paths, but nothing tests the store, the settings decoder, the model, switching, or event re-matching. `explicit-error-handling` is partial: store and manager errors are typed and surfaced, but window-controller failures are discarded without a log (the open question on restore-failure-silent) and event operations log rather than surface persistence failures. `data-integrity` is partial because `saveAll` is atomic per file but not across files, and batch assignment can give one window to two snapshots. `state-recovery` passes because a corrupt context file is skipped rather than failing the load, and dormant snapshots keep fingerprints so windows re-attach after relaunch. `graceful-degradation` passes because a missing state file yields an empty state and a failed rules load yields an empty rule list. `no-hardcoded-strings` fails because every error and notification string is an English literal. `encryption-at-rest` fails because window titles and app names are stored in plain JSON. `no-pii-in-logs` passes because logged names and titles go through `Logger` interpolation, which is private by default.

