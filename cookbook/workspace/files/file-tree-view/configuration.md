
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `roots` | the roots model | required (no default) | Supplies the ordered list of root managers shown as top-level rows. |
| `directories` | the directories model | required (no default) | The root URLs used to resolve which root a clicked node's target-selection belongs to. |
| `selection` | the selection model | required (no default) | Shared selected-node/selected-root object; supply one to let a host read or drive the selection. |
| `restoration` | the restoration model | required (no default) | Shared expanded-paths/selected-path object; supply one to restore or persist disclosure and selection across launches. |
| `documentStore` | the document store | required (no default) | App-wide open-document registry; supplies the dirty state shown by each file row's unsaved-changes marker. |
| `onOpenRequest` | a callback taking a file URL and a destination value, optional | `nil` | Set by a host to receive open requests — from a click, double-click, or context-menu choice — naming the file and where it should be shown (`.current`, `.newTab`, or `.toTheSide`). |

