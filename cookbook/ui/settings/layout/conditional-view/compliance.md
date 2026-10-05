
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | platform-compliance |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | accessibility |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |

`native-controls-preference` and `screen-reader-support` pass because
`ConditionalView` is a plain `NSView` that relies entirely on AppKit's own
`isHidden` to remove `child` from both the view and accessibility trees;
`idempotent-operations` passes via the `hidden != self.isHidden` guard in
`applyVisibility`; `separation-of-concerns` passes because `ConditionalView`
manages only visibility, delegating all appearance and accessibility to
`child`.

`unit-test-coverage` is partial: `EditableTableCardUpdateTests.swift` has one test (`explanationFollowsAConditionalSetting`) that builds a `ConditionalView` around a `UserSetting<Bool>` and asserts the child hides and reopens when the setting flips, but no dedicated `ConditionalViewTests.swift` exists, and the initial-visibility, predicate, constructor-trap and idempotent-visibility paths are untested.

