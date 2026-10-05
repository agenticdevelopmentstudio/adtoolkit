
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `severity` | `ExtensionMessageSeverity` | none (required) | Which `show*Message` call produced this request. |
| `message` | `String` | none (required) | The primary text to present; no length or emptiness constraint. |
| `detail` | `String?` | none (required argument; `nil` denotes "no detail") | Optional secondary text. |
| `isModal` | `Bool` | none (required) | The caller's stated modality preference; carried but not enforced, per **is-modal-carried-not-enforced**. |
| `itemTitles` | `[String]` | none (required; empty array denotes no buttons) | Button titles in display order; also the domain `presentMessage(_:)`'s returned index is drawn from. |
| `closeAffordanceIndices` | `[Int]` | none (required; empty array denotes no flagged items) | Indices into `itemTitles` whose item the extension flagged `isCloseAffordance`. |

