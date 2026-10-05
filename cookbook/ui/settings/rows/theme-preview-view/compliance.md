
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | Platform Compliance |
| [platform-theming](agenticdevelopercookbook://compliance/platform-compliance#platform-theming) | passed | Platform Compliance |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`keyboard-navigable` and `reduced-motion` are omitted: `ThemePreviewView.swift`
has no `NSControl`, target-action, or interactive element of any kind (see
States/Pressed) and no `NSAnimationContext`/animator proxy or transition of
any kind (see Accessibility Options/Reduce Motion), so neither check applies.
The remaining statuses rest on `ThemePreviewView.swift` itself: every color
and role-styled font is read through `SemanticPalette`/`TerminalAppearance`
role lookups, never a raw literal (the passed checks above); no
`setAccessibilityRole`/`setAccessibilityElement`/label override is set on any
container view, leaving VoiceOver labeling only partially met by AppKit's
default static-text role on each label (`screen-reader-support`, partial);
and every visible string is a
literal passed to `NSTextField(labelWithString:)`, never routed through
`NSLocalizedString` (`no-hardcoded-strings`, failed).

`unit-test-coverage` is `partial` because `ThemeUITests.swift` (`preview`) constructs a `ThemePreviewView` for a built-in theme, calls `show` with another and asserts only that it has subviews; the rendered sample content is not asserted.

