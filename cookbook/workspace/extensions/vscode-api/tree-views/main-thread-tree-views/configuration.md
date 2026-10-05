
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `notImplementedLedger` | ledger (shared) | none (required) | Shared record of unimplemented `vscode` members this extension reached for; passed to every registration this bridge creates. |
| `extensionIdentifier` | string | none (required) | The extension this bridge instance belongs to; attributed on every ledger row and every log line. |
| `commands` | registry | none (required) | The registry activation dispatches a row's declared command through. |
| `TreeViewOptions.canSelectMany` | boolean | `false` | Read when creating a tree view; sets the registration's allows-multiple-selection setting. |
| `TreeViewOptions.showCollapseAll` | boolean | `false` | Read when creating a tree view; `true` records a not-implemented ledger row and has no other effect. |
| `TreeViewOptions.dragAndDropController` | object | absent | Read when creating a tree view; presence records a not-implemented ledger row and has no other effect. |
| `TreeViewOptions.manageCheckboxStateManually` | boolean | `false` | Read when creating a tree view; `true` records a not-implemented ledger row and has no other effect. |

