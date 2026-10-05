
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `paneName` | string | `""` | Name shown above the toolbar; setting it updates the label immediately. |
| `onAdd` | callback or unset | unset | Invoked when the Add button is tapped. |
| `onRemove` | callback or unset | unset | Invoked when the Remove button is tapped. |
| `onMove` | callback (direction) → none, or unset | unset | Invoked with the chosen direction when a Move menu item is selected. |
| `onDone` | callback or unset | unset | Invoked when the Done button is tapped. |
| `canAdd` | callback () → boolean | `true` | Re-read when availability is refreshed to set the Add button's enabled state. |
| `canRemove` | callback () → boolean | `true` | Re-read when availability is refreshed to set the Remove button's enabled state. |
| `availableDirections` | callback () → set of directions | empty set | Re-read when availability is refreshed to decide which Move menu items are enabled. |

