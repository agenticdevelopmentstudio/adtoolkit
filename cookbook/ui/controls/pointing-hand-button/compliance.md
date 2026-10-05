
| Check | Status | Category |
|-------|--------|----------|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`keyboard-navigable` and `screen-reader-support` pass because this
component overrides no keyboard, focus, or accessibility method, leaving
the platform's default button's own compliant behavior intact.
`native-controls-preference` passes because the whole implementation is
the platform's own system pointing-hand and arrow cursors, with no custom
cursor image.

`separation-of-concerns` passes because `PointingHandButton` adds only the pointing-hand cursor over its bounds and leaves title, action and styling to the ordinary button it subclasses. `unit-test-coverage` is `failed`: a search of the Apple test targets finds no test file for `PointingHandButton`, so the cursor behavior is unpinned by automated tests.

