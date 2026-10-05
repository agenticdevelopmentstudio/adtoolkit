
| Check | Status | Category |
|-------|--------|----------|
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Statuses rest on `SettingsPanelViewController.swift` itself: it composes
only native `NSViewController`/`NSHostingView` APIs, never reimplementing
their layout (`native-controls-preference`: passed), but it sets no
accessibility role or label of its own — that responsibility belongs to the
`GroupView`s and SwiftUI content a subclass hosts — so `screen-reader-support`
is only `partial` here, not exercised or violated by this file.

`separation-of-concerns` passes because `SettingsPanelViewController` only holds a descriptor, exposes its panel-view content, forwards groups to it, and offers overridable help/search/scroll defaults; layout, scrolling and help chrome live in the panel view, panel host and split view. `unit-test-coverage` is partial because there is no test file for `SettingsPanelViewController` itself: its `searchKeywords` and help-content overrides are exercised through the `TestPanel` subclass in `SettingsSearchIndexTests.swift`, and `SettingsCardViewsTests.swift` calls its `hostingView(for:)` helper, but the descriptor-immutability, default-descriptor, add-group and hosts-own-scroll defaults have no test.

