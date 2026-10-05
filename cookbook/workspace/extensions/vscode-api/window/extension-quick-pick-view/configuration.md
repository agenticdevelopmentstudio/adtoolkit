
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `model` | `ExtensionQuickPickModel` | — (required) | Owns `request` (title, placeholder, items, `canPickMany`, `matchOnDescription`/`matchOnDetail`), the filter query, `visibleIndices`, `highlightedIndex`, and `checkedIndices`. Supplied once at construction and never replaced. |
| `onAccept` | callback taking the list of chosen indices | no-op | Called with the chosen indices into `model.request.items` when the user accepts (Return, or a single-select click). |
| `onCancel` | callback taking no arguments | no-op | Called on Escape (key or window-level handling); not part of this component's focus-loss handling, which is the hosting window's concern, not this component's. |
| `onHighlight` | callback taking the highlighted item index | no-op | Called from the single place the highlight is synced to the table, whenever a row becomes highlighted. |

