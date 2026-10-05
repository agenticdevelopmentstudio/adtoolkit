
| Check | Status | Category |
|-------|--------|----------|
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | failed | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Keyboard-navigable is failed because `TabButton`/`TabItemHostView` have no
key-view-loop or `keyDown` wiring (see Accessibility).
Screen-reader-support is partial: it holds for `.title` tabs, where
`TabButton` sets a real accessibility role, title, value, and a republished
close-button child, but no accessibility notification is posted for a
programmatic active-tab change — a fallback activation, or the sibling-selection
update across an edge's other tabs (see Accessibility). String-externalization
is failed because the close button's "Close Tab" accessibility description is
a hardcoded English literal (see Localization). `@MainActor` confinement, the
single-active-tab invariant, and the color-only selection cue are true of the
source (see Behavioral Requirements and Accessibility Options) but are not
compliance-catalog checks, so they are not listed here.

`separation-of-concerns` passes because `MultiTabbedViewController` only arranges the edge-docked tab groups and their visibility; tab content, persistence and window chrome come from callers. `unit-test-coverage` is `partial`: `MultiTabbed/MultiTabbedActiveTabTests.swift`, `MultiTabbedHostedItemTests.swift`, `TabCardStackTests.swift`, `TabBarAccessibilityTests.swift` and `TabBarStartInsetTests.swift` cover it, but not every edge-docking vector.

