
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | Platform Compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

Native-controls-preference and platform-design-language pass because the
component is a stock pull-down/menu control with no custom drawing.
Keyboard-navigable passes on the platform's inherited keyboard support for
this control (Space/Return opens the menu; arrow keys and type-to-select
navigate it), unmodified by this component. Screen-reader-support passes
because the accessible name is the same title-based string always shown on
screen, and that string always states both the filtered axis and the
current selection (see **Label requirements** under Accessibility).
Contrast-ratio is `partial` because the resolved theme colors are never
checked for contrast in source (see the open question on **contrast**).
String-externalization is failed because the "Any" and "{n} selected"
strings are hardcoded English literals with no localization key (see
Localization).

`separation-of-concerns` passes because the control owns only the menu, the title summary and the checkmarks, takes its choices as caller-supplied id/title/detail values and reports changes through `onChange`, leaving the meaning of an id to the caller. `unit-test-coverage` is `failed`: a search of the Apple test targets finds no test file for `MultiChoiceFilterButton`, so vectors 001 through 026 are unpinned by automated tests.

