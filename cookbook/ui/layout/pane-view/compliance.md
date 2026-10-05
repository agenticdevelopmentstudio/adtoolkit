
| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | partial | Reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Statuses rest on `PaneViewController.swift` and `PaneSpacingOverride.swift` as built: the gear and spacing-reset buttons carry real accessibility labels and identifiers, but no `NSAccessibility` notification is posted anywhere when the title, minimize state, or zoom state changes (`screen-reader-support`, partial); every user-facing string (`fallbackTitle`, the gear's tooltip/label, the "Settings…" and "Use Default" titles) is a hardcoded Swift literal with no localization key (`string-externalization`, failed); `PaneSpacingOverride`'s `JSONEncoder`/`JSONDecoder` calls are wrapped in `try?` so a corrupt or unwritable row is silently dropped rather than reported (`data-integrity`, partial); and the default `EphemeralPaneStateStore` keeps state in memory only, so nothing survives an actual process restart unless the caller injects a persistent store (`state-recovery`, partial).

`separation-of-concerns` passes because `PaneViewController` supplies only the title bar, content hosting and host-mediated close, minimize, zoom and restore actions; what the actions do is decided by the host. `unit-test-coverage` is `partial`: `Panes/PaneViewControllerTests.swift` and `Panes/PaneCapabilitiesTests.swift` cover the chrome and capabilities, but not every vector.

