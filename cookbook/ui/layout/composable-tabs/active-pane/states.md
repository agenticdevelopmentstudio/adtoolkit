
| State | Appearance change |
|-------|--------------------|
| No pane has claimed the window yet | No pane's backdrop draws the accent color; every pane reads as "inactive" (hairline outline) until the first arrival claims the spot. |
| Active pane, window focused, highlighting enabled | 2pt border in the active-pane-outline color; backdrop in the pane-backdrop color. |
| Active pane, window not focused (not focused and no focused attached sheet) | 2pt border in the pane-outline color, same as an inactive pane. |
| Active pane, highlighting disabled (by user setting or theme override) | 2pt border in the pane-outline color, same as an inactive pane. |
| Inactive pane | 2pt border in the pane-outline color; backdrop in the pane-backdrop color. |
| Arrange mode enabled in the window | Pointer movement no longer changes the active pane; clicks still do. |
| Window has an attached sheet | Pointer movement no longer changes the active pane in that window; the sheet itself has the keys. |

