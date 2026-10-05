
| State | Appearance change |
|-------|------------------|
| Default | Rack icon plus button showing the current computed label; no popover shown. |
| No servers configured | Button text reads "No MCP servers"; if opened, the popover shows the empty-state message instead of any row. |
| Servers configured, none active | Button text reads "MCP: none". |
| Servers configured, some or all active | Button text reads "MCP: {active} of {total}". |
| Picker open | `showingPicker == true`; a popover anchored below the button presents the server picker. |
| Picker closed | `showingPicker == false` (the initial value); no popover is shown. |
| Server row checked/unchecked | A row's toggle shows checked when `viewModel.isActive(id)` is true; tapping it calls `viewModel.toggle(id)`, flipping membership and writing the new set back to the caller's binding. |
| Pressed | Not applicable — the toggle button uses a borderless style with no additional pressed-state styling; any momentary highlight is the system borderless-button style's own, not authored here. |
| Disabled | Not applicable — no control in this component (the button or any row toggle) is ever explicitly disabled; every control is always interactive. |
| Focused | Not applicable — no custom focus-ring styling is applied; standard system focus-ring behavior for a button/toggle is inherited, not authored. |
| Loading | Not applicable — the server list delivers its current value synchronously on subscription; the component defines no loading/pending indicator. |

