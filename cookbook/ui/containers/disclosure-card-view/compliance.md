
| Check | Status | Category |
|-------|--------|----------|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | Platform Compliance |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

`keyboard-navigable`, `native-controls-preference`, and
`platform-design-language` rest on what the source visibly does (the native
`NSButton`/`NSStackView` controls); `screen-reader-support` and `contrast-ratio`
are `partial` because the source cannot settle, respectively, the disclosure
label's staleness between a click and the host's rebuild (see
`does-not-self-mutate-on-toggle`) and each shipped theme's actual resolved
contrast ratios; `no-hardcoded-strings` is `failed` because
`"Show details"`/`"Hide details"` are English literals with no
localization key (see Localization).

`separation-of-concerns` passes because the card is a pure presentation view: it takes its content, title, summary and palette as inputs, reports a click only through `onToggle`, and leaves fold state to a host-owned `CardFoldMemory`, so no persistence or navigation logic lives in the view (see `does-not-self-mutate-on-toggle`). `unit-test-coverage` is `partial`: `UI/DisclosureCardTests.swift` pins the fold-memory contract, the card's width and height rules (`testAFoldedCardIsExactlyAsWideAsAnOpenOne`, `testACardIsNeverNarrowerThanTheContentItIsHiding`), the title status symbol and its palette tint and spoken label (`testTheSymbolAfterTheNameIsSpokenAndTintedFromTheLivePalette`) and the corner badge's spoken label, but nothing there exercises the surface, outline, titlebar and text palette mapping, the toggle callback, or the disclosure control's labels.

