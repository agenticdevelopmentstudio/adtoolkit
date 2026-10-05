
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | passed | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | Internationalization |
| [rtl-layout-support](agenticdevelopercookbook://compliance/internationalization#rtl-layout-support) | passed | Internationalization |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |

`screen-reader-support` is partial because both footer buttons have an empty
title and an image built with `accessibilityDescription: nil`, with no
explicit accessibility label set in source (see Accessibility);
`keyboard-navigable` passes because both are stock `NSButton`s with no
override disabling AppKit's default keyboard focus/activation.
`string-externalization` and `no-hardcoded-strings` fail because all five
user-facing strings are literal `String`s assigned to `toolTip`/`prompt`/
`message` (see Localization); `rtl-layout-support` passes because the layout
uses only `leadingAnchor`/`trailingAnchor` constraints, which AppKit mirrors
automatically for right-to-left locales. `data-minimization` passes because
`directories`/`selection` change only in response to an explicit user action
(the open panel, or a click in the tree), never automatically (see Privacy).

`separation-of-concerns` passes because `FileBrowserViewController` composes the browser from separate parts, with per-root tree state in `FileTreeManager`, the outline in `FileTreeOutlineViewController`, the roots list in the `FileBrowserRootsModel` observable object, and pane teardown and selection description in the `PaneContentTeardown` and `PaneSelectionDescribing` extensions. `unit-test-coverage` is partial: `FileTreeManagerInjectedProviderTests.swift` constructs the real controller to check provider injection and per-root scoping, and `FileBrowserRestorationStateTests.swift` and `SelectionSyncTests.swift` cover the restoration state and selection sync it relies on, but no test drives its layout, multi-root header, or teardown.

