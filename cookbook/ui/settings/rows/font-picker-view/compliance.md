
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | platform-compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | platform-compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | accessibility |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | internationalization |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`native-controls-preference` and `platform-design-language` pass because the
component defers to `FontChooserButton`'s own use of the system font panel
rather than building a second font browser. `keyboard-navigable` passes on
`NSButton`'s inherited Tab/Space/Return handling. `screen-reader-support` is
`partial`: `button`'s own accessible name (its `title`) is meaningful, but
`FontPickerView.swift` sets no `accessibilityLabel`/`setAccessibilityTitleUIElement`
linking `button` to the row's descriptive `label`, unlike the sibling
`CheckboxView`/`NumberFieldView`/`PopupMenuChoiceView` rows (see Label
requirements under Accessibility). `contrast-ratio` is `partial`: the
resolved contrast of the 40%-alpha disabled label cannot be determined
from this file alone (see the open question on minimum-contrast-ratio
under Accessibility).
`idempotent-operations` passes because repeated `sync()` calls always
converge to the same observable state (see Edge Cases).
`separation-of-concerns` passes because the component stores no font of its
own beyond its reference to `viewModel`, and delegates all font-resolution
fallback to `FontViewModel.font` (see **delegates-font-resolution-fallback**).
`string-externalization` fails because `describe(_:installed:)`
builds its output from hardcoded, unlocalized string fragments (see
Localization).

No test in the repository's test targets constructs `FontPickerView`, so `unit-test-coverage` is `failed`: a search of `AgenticToolkitMacOSTests` and the other test targets for the type name finds nothing. `FontChooserButtonTests.swift` covers only the button this row composes, not the row's binding, resync or dimming.

