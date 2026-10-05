
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| permission-row-001 | renders-title-from-permission | Construct with the Accessibility permission | Title label text is exactly `"Accessibility"`. |
| permission-row-002 | renders-title-from-permission | Construct with the Automation permission targeting a bundle identifier for which no matching app is installed (`"com.googlecode.iterm2"`) | Title label text is `"Automation — com.googlecode.iterm2"` (falls back to the raw bundle identifier). |
| permission-row-003 | renders-description-from-permission | Construct with the Keychain permission for the service `"Claude Code-credentials"` | Description label text reads `Lets this app read the "Claude Code-credentials" item in your keychain directly, instead of asking another tool for it.` |
| permission-row-004 | renders-icon-from-permission | Construct with the Microphone permission | The icon view found among the row's subviews resolves the symbol named `mic`, reports a configuration of point size 16 / weight regular, and has its tint color set to the secondary label color. |
| permission-row-005 | initial-status-is-checking | Construct a row, do not refresh it | The displayed status text reads `"Checking…"`. |
| permission-row-006 | refresh-queries-checker | Stub the status checker to return granted; refresh the row | The displayed status text reads `"Granted"`. |
| permission-row-007 | cancelled-refresh-does-not-apply | Start a refresh, cancel its underlying asynchronous work before the status checker returns, then await its completion | The displayed status text remains `"Checking…"`. |
| permission-row-008 | granted-status-appearance | The status checker returns granted; refresh the row | The displayed status text reads `"Granted"`; the status dot's color is the success color. |
| permission-row-009 | denied-status-appearance | The status checker returns denied; refresh the row | The displayed status text reads `"Not Granted"`; the status dot's color is the warning color. |
| permission-row-010 | undetermined-status-appearance | The status checker returns undetermined; refresh the row | The displayed status text reads `"Unknown"`; the status dot's color is the secondary label color. |
| permission-row-011 | status-conveyed-by-text-and-color | Refresh a row through all three statuses in turn | For each status, both the displayed text and the status dot's color differ from the other two statuses — no two statuses share the same text or the same color. |
| permission-row-012 | granted-button-title | The Keychain permission; the status checker returns granted; refresh the row | The displayed action-button title reads `"Open Settings"`. |
| permission-row-013 | ungranted-button-title | The Keychain permission for service `"Claude Code-credentials"`; the status checker returns denied, then separately undetermined; refresh the row on each | Both rows' displayed action-button title reads `"Allow…"`. |
| permission-row-014 | button-width-fits-widest-title | Construct two rows with different permissions | Both rows' action buttons report the same width, equal to the fitting width of the longer of `"Open Settings"` / `"Allow…"`. |
| permission-row-015 | action-carries-displayed-status | The status checker returns denied; refresh the row; trigger the action via its test-only trigger | The action handler is invoked with the permission and denied. |
| permission-row-016 | action-button-has-stable-identifier | Construct with the Location permission | The action button's accessibility identifier is `"permission.location.action"`. |
| permission-row-017 | row-has-no-accessibility-identifier | Construct any row | The row itself is not an accessibility element and has no accessibility identifier set. |
| permission-row-018 | minimum-row-height | Construct any row and let its layout resolve | Resolved height is `>= 72` points. |
| permission-row-019 | card-appearance | Construct any row | The row is rendered with a backing layer; its corner radius is `8`; its border width is `0.5`; its background color is white at 3% opacity; its border color is white at 6% opacity. |
| permission-row-020 | keyboard-activates-action | Construct any row, move keyboard focus to the action button, then perform its primary activation key (Space/Return) | The action handler is invoked the same way it is by the test-only trigger or a pointer click, since the action control is an unmodified standard button. |
| permission-row-021 | pre-refresh-action-enabled | Construct a row, do not refresh it, then trigger the action via its test-only trigger | The action button remains enabled throughout, and the action handler is invoked with the permission and undetermined. |
| permission-row-022 | confines-to-ui-thread | Use the component from a thread other than the UI thread | The use is rejected, at build time or by a runtime check; the component's state is unchanged |

