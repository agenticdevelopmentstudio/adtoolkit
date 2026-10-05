
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | failed | Accessibility |

Both statuses rest on `ExplanationView.swift`'s reliance on the theme's
`.secondaryText`/`.caption` roles: contrast is partial because
`SemanticPalette` enforces only a 3.0 minimum ratio (see Accessibility
above), and dynamic-type-support fails because
`ThemeTypography+NSFont.swift`'s `nsFont(scaledSize:)` builds fonts through
fixed-point-size calls (`NSFont.systemFont(ofSize:weight:)` or a named-family
lookup at an explicit size) rather than `NSFont.preferredFont(forTextStyle:)`
or any observation of the system's content-size-category setting.

Separation-of-concerns is passed: `ExplanationView` only wraps a themed label and exposes `text`, `isHidden` and the visibility callback, leaving colors to the theme and row layout to its container. Unit-test-coverage is partial: `EditableTableCardUpdateTests.swift` has a test (`an ExplanationView hidden before it is placed reopens its row when shown`) and `ExtensionsSettingsPanelTests.swift` reads the text of explanations, but no dedicated `ExplanationViewTests.swift` exists and wrapping, sizing and constructor-trap behavior are untested.

