
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |
| [native-controls-preference](agenticdevelopercookbook://compliance/platform-compliance#native-controls-preference) | passed | Platform Compliance |
| [platform-design-language](agenticdevelopercookbook://compliance/platform-compliance#platform-design-language) | passed | Platform Compliance |
| [keyboard-navigable](agenticdevelopercookbook://compliance/accessibility#keyboard-navigable) | partial | Accessibility |
| [screen-reader-support](agenticdevelopercookbook://compliance/accessibility#screen-reader-support) | partial | Accessibility |
| [string-externalization](agenticdevelopercookbook://compliance/internationalization#string-externalization) | failed | Internationalization |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |

Native-controls-preference and platform-design-language pass because the bar
composes standard SwiftUI controls (`Button`, `Toggle`, `Text`, `Image`) with
system styles (`.borderless`, `.checkbox`) and a system `.popover`, rather
than custom-drawn chrome. Keyboard-navigable is partial: these are standard,
framework-provided controls, but the toggle button uses `.buttonStyle(.borderless)`,
and a borderless SwiftUI button on macOS is only Tab-reachable when Full
Keyboard Access is enabled; no keyboard-navigation test of this bar exists in
source. Screen-reader-support is partial: button and row labels come from visible
`Text` content with no explicit override, but the "server.rack" icon is a
separate, ungrouped accessibility element next to the button (see **Label
requirements** under Accessibility, and **icon-grouping**)
and no explicit announcement accompanies a label or toggle-state change.
String-externalization is failed because the button's three label strings
and the "Unknown" row fallback are unlocalized `String` values with no
string-table lookup (see Localization). Separation-of-concerns passes because
`MCPChipsBarViewModel` owns all registry/binding logic, leaving
`MCPChipsBar` and `MCPServerPicker` as plain rendering of that model's
published state.

`unit-test-coverage` fails because no test file or test mentions `MCPChipsBarView`, `MCPChipsBar` or `MCPChipsBarViewModel` under the Apple test targets, so the active-server toggle logic (`isActive`, `toggle`) is untested.

