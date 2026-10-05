
| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [focus-management](agenticdevelopercookbook://compliance/accessibility#focus-management) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | passed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Accessibility statuses rest on the explicit `accessibilityDescription` labels alongside the unaddressed VoiceOver-notification and Differentiate-Without-Color gaps recorded in Accessibility and Accessibility Options, the theme-delegated colors and heading-style label recorded in Appearance, and the native `NSAlert` modal/sheet handling in `confirmAndRemove()`; internationalization statuses rest on the hardcoded literals listed in Localization and the `leadingAnchor`/`trailingAnchor` overlay constraints in `installArrangeOverlay()`.

`separation-of-concerns` passes because `ComposableTabsPaneViewController` only hosts registry-vended content and its chrome; the content's behavior, the registry and the split tree are separate components. `unit-test-coverage` is `partial`: `ComposableTabsViewControllerTests.swift`, `ComposableTabsPaneChromeTests.swift` and `ComposableTabsPaneHostTests.swift` exercise leaf panes through the controller, but no test file targets the class alone.

