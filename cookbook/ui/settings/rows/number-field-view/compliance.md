
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | platform-compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | platform-compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | accessibility |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`native-controls-preference`, `platform-design-language`, `keyboard-navigable`,
`idempotent-operations`, and `separation-of-concerns` rest on the source's use
of a stock `NSTextField`'s own keyboard-and-focus behavior, its
skips-redundant-commits guard, and its single-responsibility split between the
generic view and the `SettingsNumberValue` parsing contract; `screen-reader-support`
is `partial` because `setAccessibilityTitleUIElement` gives the field a
spoken name, but an unparseable-text revert (**reverts-on-unparseable-text**)
changes `textField.stringValue` with no explicit `NSAccessibility` announcement
in source, so whether VoiceOver notices the reverted value while the field is
focused is left to AppKit's own, unverified-in-source, default behavior.

`unit-test-coverage` is `partial` because `ConfigurationContributionPointTests.swift` constructs `NumberFieldView` for both `Int` and `Double`, commits typed text, asserts a `maximum` clamp with the field text rewritten to the clamped value, and asserts that non-numeric text reverts the field; there is no dedicated test file and layout, theming and external-change resync are not asserted.

