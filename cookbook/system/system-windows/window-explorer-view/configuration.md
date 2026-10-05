
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `selectedWindowIDs` | two-way binding to a set of ids | required | The set of currently selected window ids; read and written by row and section-header toggles. |
| `excludeWindowIDs` | set of ids | `[]` | Window ids to omit entirely from the scan result. |
| `activeGroupID` | optional identifier | `nil` | When set, identifies the context whose windows are togglable instead of disabled, and whose selections a scan never prunes. |
| `refreshNotification` | optional notification name | `nil` | When set, a posted notification with this name triggers a new scan. |
| Contexts model (environment) | shared environment value | required | Supplies the full window list, per-window context ownership, and hidden-app settings. |
| Theme (environment) | theme palette | required environment value | Supplies every font and color role the view draws with. |

