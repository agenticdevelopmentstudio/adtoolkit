
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | Reliability |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |

Statuses rest on `GroupView.swift`: `native-controls-preference` reflects the
card being built from `NSStackView`/`ThemedBox` rather than a custom-drawn
control; `idempotent-operations` is `partial` because `viewDidMoveToSuperview`
activates a fresh width constraint on every attach without removing one from
a prior superview (see Design Decisions); and `screen-reader-support` is
`partial` because no accessibility grouping ties the header to
`cardView`/`rowStack` (see Accessibility).

Separation-of-concerns is passed: `GroupView` owns only the card layout (a title header, rows with separators and self-hiding rows) via its private `CardRow`, while row content, explanations and visibility come from the views added to it. Unit-test-coverage is partial: no dedicated `GroupViewTests.swift` exists, but `EditableTableCardUpdateTests.swift` (rows reopening around a hidden `ExplanationView` and a `ConditionalView`), `SettingsSearchIndexTests.swift` and `KeyCommandsPanelHierarchyTests.swift` construct real `GroupView` cards and assert on their contents and nesting; separator updates and the width-constraint behavior are untested.

