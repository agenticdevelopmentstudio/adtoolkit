
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | partial | Platform Compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

`native-controls-preference` is `passed` because every element is a stock
`NSButton`/`NSTextField`/`NSImageView`/`NSStackView`; `platform-design-language`
and `contrast-ratio` are `partial` because `buildLayout()` fills and borders
the card with fixed, non-semantic `NSColor.white.withAlphaComponent(...)`
values (see the dark-only Design Decision above and the open question on
contrast) rather than an appearance-adaptive token, so neither HIG
conformance nor a 4.5:1 contrast ratio can be confirmed for every host
background; `keyboard-navigable` is `passed` because the action button is an
unmodified `NSButton`, which keeps AppKit's native keyboard focus and
activation (see **keyboard-activates-action**).

`separation-of-concerns` is `passed` because `PermissionRowView` only renders one card and reports the action; the status read goes through the injected `PermissionChecking` and the grant flow through the `onAction` callback, so neither is decided inside the view. `unit-test-coverage` is `passed` because `Tests/AgenticToolkitPermissionsUITests/PermissionRowViewTests.swift` exercises the row with a stub checker: the Granted, Not Granted and Unknown labels, the action offered for granted and non-granted rows, the status the action reports, and a refresh cancelled mid-read.

