
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `request` (parameter of `putOrUpdateStatusBarItem`) | `ExtensionStatusBarItemRequest` | none (required) | The full display state of one status bar item to put up or refresh. |
| `internalID` (parameter of `removeStatusBarItem`) | `String` | none (required) | The registry key of the item to take down; safe to pass an id the conformer never received. |
| `ExtensionStatusBarItemRequest.internalID` | `String` | none (required) | Set once by the caller at construction — the extension's supplied id folded with a per-process ordinal, or a bare ordinal when the extension gave none; never shown to the extension. |
| `ExtensionStatusBarItemRequest.id` | `String` | none (required) | The public `StatusBarItem.id` the extension sees; not guaranteed unique across items. |
| `ExtensionStatusBarItemRequest.alignment` | `ExtensionStatusBarAlignment` | none (required) | `.left` or `.right`; fixed for the item's lifetime. |
| `ExtensionStatusBarItemRequest.priority` | `Double?` | `nil` | `nil` means "the extension supplied no priority"; never coerced to `0`. |
| `ExtensionStatusBarItemRequest.name` | `String?` | `nil` | Extension-supplied display name. |
| `ExtensionStatusBarItemRequest.text` | `String` | none (required, caller initializes to `""`) | The item's rendered text; the one field every request always carries a concrete value for. |
| `ExtensionStatusBarItemRequest.tooltip` | `String?` | `nil` | The string form of `StatusBarItem.tooltip`; a `MarkdownString` write is recorded elsewhere as not implemented rather than reaching this field. |
| `ExtensionStatusBarItemRequest.color` / `.backgroundColor` | `String?` | `nil` | The flat id string for either a plain color string or a `ThemeColor`'s `id`; see **color-flat-string**. |
| `ExtensionStatusBarItemRequest.command` | `String?` | `nil` | The string form of `StatusBarItem.command`; a `Command`-object write is likewise recorded elsewhere as not implemented. |
| `ExtensionStatusBarItemRequest.accessibilityLabel` / `.accessibilityRole` | `String?` | `nil` | Extension-supplied `accessibilityInformation` fields, carried through unchanged. |

