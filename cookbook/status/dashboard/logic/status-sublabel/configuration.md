
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `state` | one of `"ok"`, `"warn"`, `"down"` | none (required) | Chooses the clear-board line (`"ok"`) or the problem breakdown (anything else). |
| `healthyCount` | number | none (required) | Number of endpoints reporting healthy; used only when `state` is `"ok"`. |
| `servicesLength` | number | none (required) | Number of endpoints monitored; used only when `state` is `"ok"`. |
| `problems` | a list of rows | none (required) | The problem rows; only `statusWord` is read, and only when `state` is not `"ok"`. |
| the sublabel-phrase table | internal lookup table | seven compiled-in entries | Private map from status word to phrase formatter; not configurable by callers. |

This logic reads no environment variables or settings keys and takes no injected dependencies. It imports only type definitions.

