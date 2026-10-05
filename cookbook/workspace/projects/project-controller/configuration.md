
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workspace` (construction parameter) | workspace reference | none — required | The project this controller reconciles; supplies the git client, the project directory, stored/persisted tabs, the default layout blueprint, and a per-directory status provider. |
| `commandRegistry` (construction parameter) | command-registry reference, optional | none — required parameter; may be absent | Where branch commands are registered and unregistered. Absent disables command-palette integration for this project: every register/unregister call becomes a no-op. |
| `onTabsDidChange` | callback, optional | absent | Caller-set callback fired after a reconcile persists a changed tab set. |
| `onWillChangeTabs` | callback, optional | absent | Caller-set callback fired immediately before persisting tabs, in the same execution step. |
| `onTabItemsNeedRefresh` | callback, optional | absent | Caller-set callback fired when the checkouts changed but the tab plan itself did not. |

This controller reads no environment variable and no settings key
directly; the git executable path, timeout, and submodule handling are the
git client's own configuration concern, reached only indirectly through
the workspace.

