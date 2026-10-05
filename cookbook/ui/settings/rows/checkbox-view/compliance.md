
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | platform-compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | platform-compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | accessibility |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | partial | reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`keyboard-navigable` and `screen-reader-support` rest on `toggle` being an
unmodified `NSSwitch`/`NSControl` with `setAccessibilityTitleUIElement` set
(no focus, key-handling, or accessibility-role override anywhere in
source — see **inherits-native-keyboard-focus** and
**links-toggle-accessibility-title**); `idempotent-operations` is `partial`
because repeated commits of the same toggle value are a no-op
(**skips-redundant-commits**), but constructing a second observer against
the same `viewModel` is not idempotent — it silently overwrites the prior
`onChange` handler (**claims-sole-onchange-observer**).

`unit-test-coverage` is `partial` because there is no `CheckboxViewTests` file, but `SettingObservingTests.swift` (`testViewModelClosureInitDrivesACheckbox`) constructs a `CheckboxView` and checks its toggle state and write-through to the view model, and `EditableTableCardUpdateTests.swift` and `ConfigurationContributionPointTests.swift` build it inside groups and assert on the resulting hierarchy; the click-to-commit and external-change resync paths are not exercised directly.

