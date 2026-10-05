
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | platform-compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | platform-compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | accessibility |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | internationalization |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

The `native-controls-preference` and `platform-design-language` checks pass
because the component defers to macOS's own `NSFontPanel` rather than
building a second font browser (per the source's own doc comment,
`native-controls`). `keyboard-navigable` and `screen-reader-support` pass on
`NSButton`'s inherited Space/Tab handling and the caller-supplied,
availability-aware `title` (see **Label** under Accessibility).
`idempotent-operations` passes because repeated `show(_:title:)` calls with
the same arguments always leave the button in the same observable state,
and repeated presses that re-run `openFontPanel(_:)` are likewise
idempotent: reassigning `NSFontManager.shared.target` and re-seeding
`setSelectedFont` to the same values are no-ops, and calling
`orderFrontFontPanel(_:)` again on an already-frontmost panel leaves it in
the same state. `separation-of-concerns` passes because the component
stores no font of its own beyond the in-memory `selectedFont` (see
#requirements/font-persistence). `string-externalization` fails because
the built-in `"System"` initial title is a hardcoded literal with no
localization key (see Localization).

`unit-test-coverage` passes because `FontChooserButtonTests.swift` exercises the button directly: the chosen font drawn at the sample size, the chosen size surviving a small draw, the no-font case drawing the system font and recording nothing, the panel offering only font-picking parts, and the button handing back the font manager's target when its window is left.

