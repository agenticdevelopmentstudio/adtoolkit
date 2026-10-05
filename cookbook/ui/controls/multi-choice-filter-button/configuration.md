
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `label` | String | — (required) | Names the filtered axis (e.g. `"Good for"`); prefixes every title-summary state and is item 0's own (unselectable) menu title. |
| `choices` | List of Choice | — (required) | The fixed, ordered list of selectable entries; also fixes the order `formats-title-few-selected` joins titles in. |
| `onChange` | Callback | none | Assigned by the caller after construction; invoked with the new `selection` on every actual change (see **fires-on-change-on-actual-change**). |
| `Choice.id` | String | — (required) | Opaque identifier the caller maps back to its own type; membership in `selection` is keyed by this value. |
| `Choice.title` | String | — (required) | The menu item's display title and the text used in the few-selected title summary. |
| `Choice.detail` | String | `""` | Tooltip text for choices whose meaning a title alone can't carry; empty means no tooltip is set (see **sets-choice-tooltip**). |

