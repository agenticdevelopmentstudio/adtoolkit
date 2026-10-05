
| State | Appearance change |
|-------|------------------|
| Default (constructed, before first refresh) | The status label reads `"Checking…"` (its initial value); the status dot has no color assigned yet (only a status-apply call sets one); the action button's title already reads the permission's own action title, set unconditionally during layout, independent of any status read. |
| Granted | Status dot color becomes the success color; status label reads `"Granted"` in the success color; action button title becomes `"Open Settings"`. |
| Denied | Status dot color becomes the warning color; status label reads `"Not Granted"` in the warning color; action button title becomes the permission's own action title. |
| Undetermined | Status dot color becomes the secondary label color; status label reads `"Unknown"` in the secondary label color; action button title becomes the permission's own action title. |
| Pressed | Not applicable to the row itself: the row is not a control. The action button's own pressed appearance is the platform's default button-press highlight, unstyled by this component. |
| Disabled | Not implemented in source: the action button, the row, or any subview is never disabled. The button stays interactive in every status, including before the first refresh completes — pressing it then reports undetermined, the displayed status's initial value. |
| Focused | Not styled by this component: any focus ring on the action button when focused is the platform's own native focus appearance. |
| Loading | Same as "Default (constructed, before first refresh)" above — this component has one pre-refresh state, shown as `"Checking…"`, not a distinct spinner or progress indicator. |

