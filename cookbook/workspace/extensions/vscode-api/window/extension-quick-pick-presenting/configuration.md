
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `request` | `ExtensionQuickPickRequest` | none (required) | The whole call's input to `presentQuickPick`; a conformer reads it to build what it shows. |
| `onHighlight` | callback taking an item index | none (required) | Invoked by the conformer with an index into `request.items` each time the highlighted row changes. |
| `request.title` | `String?` | `nil` | `QuickPickOptions.title`. |
| `request.placeHolder` | `String?` | `nil` | `QuickPickOptions.placeHolder`; filter-field placeholder text. |
| `request.prompt` | `String?` | `nil` | `QuickPickOptions.prompt`; carried but read by nothing this file's own consumer builds. |
| `request.items` | `[ExtensionQuickPickItem]` | none (required) | The rows to present, in extension-supplied order, separators included. |
| `request.canPickMany` | `Bool` | none (required) | `QuickPickOptions.canPickMany`; whether more than one row may be accepted. |
| `request.matchOnDescription` | `Bool` | none (required) | `QuickPickOptions.matchOnDescription`; whether `description` participates in filtering (documented upstream default `false`). |
| `request.matchOnDetail` | `Bool` | none (required) | `QuickPickOptions.matchOnDetail`; whether `detail` participates in filtering (documented upstream default `false`). |
| `request.ignoreFocusOut` | `Bool` | none (required) | `QuickPickOptions.ignoreFocusOut`; whether the picker stays open when focus moves elsewhere. |

