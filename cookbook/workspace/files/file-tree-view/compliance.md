
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | partial | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [contrast-ratio](agenticdevelopercookbook://compliance/accessibility#contrast-ratio) | partial | Accessibility |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |

`keyboard-navigable` passes because the source overrides none of
`NSOutlineView`'s default keyboard/type-ahead handling
(`keyboard-and-typeahead-inherited`). `screen-reader-support` is partial: row
icons and the unsaved-changes marker carry explicit accessibility
descriptions, but the git-status badge does not (see Accessibility above).
`contrast-ratio` is partial: non-git colors resolve through
semantic theme roles whose actual contrast this file cannot show, and the
fixed git-status colors are not verified against theme backgrounds here.
`no-hardcoded-strings` and `string-externalization` fail because all ten
user-visible strings are `String` literals with no localization key (see
Localization above).

`separation-of-concerns` is partial: tree state (`FileTreeNode`, `FileTreeManager`) lives in the model layer, but `FileTreeOutlineViewController` itself holds the outline data source and delegate, the context menu (`NSMenuDelegate`), per-directory child watching (`ChildWatcher`), the open-request handling (`OpenRequest`) and its row views in one large file. `unit-test-coverage` is partial: `FileTreeContextMenuTests.swift`, `FileTreeOpenOnSelectionTests.swift`, `SelectionSyncTests.swift` and `FileTreeNodeTests.swift` construct the real controller and cover the menu, open-on-selection, selection sync and node behavior, but no test covers the row views, keyboard handling or child watching.

