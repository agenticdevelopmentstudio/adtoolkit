
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the window owns only list-to-pane mapping and selection, with chrome inherited from `SettingsWindow` and all model changes delegated to the owner through callbacks. Unit-test-coverage is partial: `RecordDetailWindowControllerTests.swift` has fifteen tests covering panes per record, selection, neighbour selection, the empty list, the footer, add and remove, the veto and single selection reports, but fixed panels, `onConfigurePanel` and the `confirm` and `reportFailure` defaults have no tests there.

