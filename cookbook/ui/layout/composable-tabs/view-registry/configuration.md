
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `displayName` | String | (required) | What the Split menu calls this view. |
| `symbolName` | String (optional) | absent | Optional icon identifier shown alongside menu items for this view. |
| `preferredAxis` | Axis (horizontal or vertical) | horizontal | The axis the Split menu proposes first for a new pane of this kind; does not forbid the other axis. |
| `minimumThickness` | Number (points) | `120` | Minimum width or height of the pane, in points. |
| `preferredThicknessFraction` | Number (optional, 0–1 fraction) | absent | Share of the enclosing split this pane asks for on first layout; absent divides evenly. |
| `isCollapsible` | Boolean | `false` | Whether the platform may collapse the pane to nothing. |
| `holdingPriority` | Layout priority value (optional) | absent | Explicit resize-resistance priority; absent derives it via the holding-priority resolution rules above. |

