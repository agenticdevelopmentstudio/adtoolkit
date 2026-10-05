
| Check | Status | Category |
|-------|--------|----------|
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [dynamic-type-support](agenticdevelopercookbook://compliance/accessibility#dynamic-type-support) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | partial | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | partial | Internationalization |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy & Data |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

`screen-reader-support` is partial because the refresh button has no explicit
`.accessibilityLabel` (see **refresh-button-label**);
`keyboard-navigable` passes because every interactive element is a standard,
keyboard-focusable `Toggle`/`Button`. `contrast-ratio` and
`no-hardcoded-strings`/`string-externalization` are partial for the same two
source-documented exceptions: the context badge's `Color(hex: ctx.color) ??
.blue` fallback sits outside the theme palette, and the `(untitled)` fallback
is routed through `Text`'s verbatim `String` initializer instead of a
localization key. `dynamic-type-support` is partial because the source
resolves every font through `theme.font(_:)` and this file cannot tell
whether that palette scales with the system text-size setting.
`data-minimization` passes because the Privacy section shows the view reads
only currently-running window data needed for display, filtered by
`appState.settings.hiddenApps`, and persists nothing.

`separation-of-concerns` is `partial` because `WindowExplorerView` renders the grouped list but its `refreshAsync` also enumerates windows, filters them by size, visibility and hidden apps, and enriches titles through the accessibility API inside the view, work that belongs in a model or service the view reads from. `unit-test-coverage` is `failed` because no test references `WindowExplorerView` or `AppWindowGroup` anywhere in the repository's test targets.

