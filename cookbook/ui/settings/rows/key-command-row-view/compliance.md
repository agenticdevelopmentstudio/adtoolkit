
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | platform-compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | platform-compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | partial | accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

The `passed` rows rest on source facts that are unconditional: the row is
`@MainActor`-isolated throughout, composes native `NSSwitch`/AppKit
controls per platform HIG, sets accessibility identifiers on the capture
field and toggle, and keeps business logic (edit/commit/toggle state) out
of its own presentation code, delegating persistence to the registry. The
`partial` rows rest on the Accessibility section's gaps: the
toggle is labeled via `setAccessibilityTitleUIElement`, but the capture
field has only an accessibility identifier and no accessibility label, and
no state change posts an `NSAccessibility` announcement, so screen-reader
support, keyboard/focus behavior around the capture field, and label
completeness are not fully implemented. `no-hardcoded-strings` is `failed`
because every user-facing string
this file introduces is a Swift literal with no localization mechanism, as
the Localization section states.

`unit-test-coverage` is `partial` because `KeyCommandBehaviourTests.swift` builds `KeyCommandRowView` rows against a registry and asserts on recording over a shipped-off command (it switches on), the switch refusing to re-enable a taken chord, and the recorder's Shift-Tab behavior, and `KeyCommandsPanelHierarchyTests.swift` asserts on the rows' place in the panel; there is no dedicated `KeyCommandRowViewTests` file and layout and reset paths are not asserted.

