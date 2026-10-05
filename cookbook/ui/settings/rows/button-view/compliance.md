
| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | passed | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | failed | Accessibility |
| [touch-target-size](agenticdevelopercookbook://compliance/accessibility#touch-target-size) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

The `passed` statuses rest on `ButtonView` using an unmodified `NSButton` for its role, label, keyboard handling, and system-chrome contrast, and on `ButtonView` defining no string literals of its own. `dynamic-type-support` is `failed` because `button.font` is never set to a text-style-based font (e.g. `NSFont.preferredFont(forTextStyle:)`), so its title does not scale with the system text-size setting. `touch-target-size` is `passed` on macOS: the button keeps the system control metrics (see **Minimum tap target** under Accessibility).

`separation-of-concerns` passes because `ButtonView` only places an `NSButton` in a row according to its `Placement` and forwards the press to the view model's `wasPressedCallback`; what the press does belongs entirely to the caller's `ButtonViewModel`. No test in the repository's test targets constructs `ButtonView`, so `unit-test-coverage` is `failed`: a search of `AgenticToolkitMacOSTests` and the other test targets for the type name finds nothing.

