
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | platform-compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | platform-compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | accessibility |
| [semantic-markup](agenticdevelopercookbook://compliance/accessibility#semantic-markup) | partial | accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | accessibility |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | partial | security |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |

`secure-storage` is partial because the field holds a potential secret
(`isPassword`) only in memory — masked on screen via
`NSSecureTextField`, never written to Keychain or any persistent store,
but also never explicitly zeroed on release. `contrast-ratio` is partial
because `validationLabel`'s three severities are distinguished by a
theme-role color change alone, with no non-color cue and no in-source
measurement of the resulting contrast ratio (see the Differentiate
Without Color entry under Accessibility Options).

`unit-test-coverage` is partial: the input box's model is covered by `ExtensionInputBoxModelTests.swift`, its `vscode.window` bridge by `MainThreadWindowInputBoxTests.swift`, and `ExtensionPickerWindowControllerTests.swift` checks that the hosting window is sized to the controller's own preferred content size, but no test constructs `ExtensionInputBoxViewController` to drive the validation label, password masking, or Return/Escape handling.

