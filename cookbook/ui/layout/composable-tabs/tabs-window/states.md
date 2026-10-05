
| State | Appearance change |
|-------|------------------|
| Default | Window not yet shown: no toolbar or titlebar accessories exist until the window is first shown. |
| Pressed | Not applicable — the window itself renders no pressable surface; per-press visuals belong to the buttons and toolbar items it hosts. |
| Disabled | Search field is disabled and grayed whenever the search target reports that it does not support search (see **search-availability**, **search-target**). |
| Focused | The active tab's last-focused leaf pane holds keyboard focus, restored on tab activation and when the window is shown. |
| Loading | Not applicable — tab and pane installation is synchronous; no loading/spinner state exists in source. |
| Arrange mode enabled | Arrange titlebar button shows accent tint and a pressed-looking active state; the bound menu item shows a checkmark. |
| Arrange mode disabled | Arrange titlebar button shows no tint and no active state; the menu item shows no checkmark. |
| Help drawer open | Help toolbar button shows the filled question-mark glyph, accent tint, and tooltip "Hide Help". |
| Help drawer closed | Help toolbar button shows the outlined question-mark glyph, secondary-text tint, and tooltip "Show Help". |
| Single remaining tab group | The tab-close affordance for that group's members MUST have no effect (see **last-group-guard**). |
| Last enabled edge | The settings toggle for that edge MUST have no effect (see **last-edge-guard**). |

