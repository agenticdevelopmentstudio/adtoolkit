
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | platform-compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | platform-compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | accessibility |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`native-controls-preference` and `platform-design-language` rest on
`textField` being an unmodified `NSSecureTextField` with AppKit's default
bezel styling (**masks-entry-with-secure-field**); `keyboard-navigable`,
`idempotent-operations`, and `separation-of-concerns` rest on behavior that
is `TextEditView`'s concern and out of this recipe's scope (the field's
inherited, unmodified `NSControl` tab order, **skips-redundant-commits**,
and the view holding no persistence or business logic of its own); `screen-
reader-support` is `partial` because `textField` has no accessibility label
linking it to `label`'s title text — see Label requirements in
Accessibility above; `contrast-ratio` is
`partial` because the inherited placeholder-text color clears only a 1.6:1
floor against WCAG's 4.5:1 threshold (see
`adtoolkit://cookbook/ui/settings/rows/text-edit-view#design-decisions`).

No test in the repository's test targets constructs `SecureTextEditView`, so `unit-test-coverage` is `failed`: a search of `AgenticToolkitMacOSTests` and the other test targets for the type name finds nothing. Its only behavior, masking, is not asserted; the inherited text-row paths are covered by `RecordFieldRefreshTests.swift` for `TextEditView` only.

