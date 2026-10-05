
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| add-pane-001 | populates-view-popup-from-choices | Two entries are offered: A with no icon, B with an icon | "Add" choice list has 2 items, titled A's display name then B's, in that order |
| add-pane-002 | sets-choice-icon-when-symbol-present | An offered entry has an icon set | That item's image is the icon, with accessibility description equal to its display name |
| add-pane-003 | omits-choice-icon-when-symbol-absent | An offered entry has no icon set | That item's image is unset |
| add-pane-004 | populates-where-popup-in-fixed-order | Any set of offered entries | "Where" choice list contains exactly 4 items titled "Left", "Right", "Above", "Below" in that order |
| add-pane-005 | defaults-where-selection-to-right | Load the sheet | The "Where" choice's selected item is "Right" |
| add-pane-006 | arranges-add-and-where-as-two-row-grid | Inspect the grid after the sheet loads | The grid has exactly 2 rows and 2 columns |
| add-pane-007 | add-row-precedes-where-row | Inspect the grid's rows | Row 0 holds the Add label/choice; row 1 holds the Where label/choice |
| add-pane-008 | ok-button-disabled-when-choices-empty | No entries are offered | The OK button is disabled |
| add-pane-009 | ok-button-enabled-when-choices-present | One entry is offered | The OK button is enabled |
| add-pane-010 | ok-button-enabled-state-fixed-at-load | Load with one entry offered; change the Where selection, then the Add selection | The OK button remains enabled, unchanged by either selection |
| add-pane-011 | cancel-precedes-ok-in-button-order | Inspect the button row's order | Cancel appears before OK |
| add-pane-012 | cancel-bound-to-escape-key | Inspect Cancel's key equivalent | Equals the Escape key |
| add-pane-013 | ok-bound-to-return-key | Inspect OK's key equivalent | Equals the Return key |
| add-pane-014 | cancel-dismisses-without-invoking-onadd | Click Cancel | The sheet is dismissed; the caller is never notified |
| add-pane-015 | confirm-dismisses-before-invoking-onadd | Select a valid Add and Where combination; click OK | Dismissal happens before the selection is reported to the caller (observable via call-order instrumentation) |
| add-pane-016 | confirm-invokes-onadd-with-selection | "Add" choice selects the second entry; "Where" choice selects "Above" | The caller is notified once, with that entry's view identifier and "above" |
| add-pane-017 | confirm-dismisses-without-onadd-on-invalid-selection | No entries are offered; the confirm action is force-invoked directly, leaving the "Add" choice's selected index invalid | The sheet is dismissed; the caller is never notified |
| add-pane-018 | enforces-minimum-container-width | Measure the container's width constraint after the sheet loads | A minimum-width constraint of 320pt exists on the container |
| add-pane-019 | root-view-accessibility-identifier | Inspect the container's accessibility identifier | Equals "composable-tabs.add-pane" |
| add-pane-020 | view-popup-accessibility-identifier | Inspect the "Add" choice list's accessibility identifier | Equals "composable-tabs.add-pane.view" |
| add-pane-021 | where-popup-accessibility-identifier | Inspect the "Where" choice list's accessibility identifier | Equals "composable-tabs.add-pane.where" |
| add-pane-022 | cancel-button-accessibility-identifier | Inspect the Cancel button's accessibility identifier | Equals "composable-tabs.add-pane.cancel" |
| add-pane-023 | ok-button-accessibility-identifier | Inspect the OK button's accessibility identifier | Equals "composable-tabs.add-pane.ok" |
| add-pane-024 | add-row-label-text | Inspect the Add row's label | Text reads "Add:"; alignment is right |
| add-pane-025 | where-row-label-text | Inspect the Where row's label | Text reads "Where:"; alignment is right |
| add-pane-026 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

