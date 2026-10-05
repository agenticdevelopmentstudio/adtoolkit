
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `model` | window-contexts model | required | The model every shortcut dispatches to; injected at construction and retained. |
| `switchToContext1` … `switchToContext9` | named shortcut | the scheme's modifier pair + 1 … + 9 | Switch to the context at index 0…8. User-customizable; persisted under the name's identifier. |
| `addWindow` | named shortcut | the scheme's modifier pair + A | Add the frontmost window to the active context. |
| `removeWindow` | named shortcut | the scheme's modifier pair + X | Remove the frontmost window from its context. |
| `nextContext` | named shortcut | the scheme's modifier pair + N | Switch to the next context. |
| `previousContext` | named shortcut | the scheme's modifier pair + P | Switch to the previous context. |
| `contextPicker` | named shortcut | the scheme's modifier pair + Space | Toggle the context picker. |
| Reservation owner | string | `"window contexts"` (hardcoded) | The owner name the key-command registry reports for these chords. Not configurable. |
| Registry | key-command registry | the app's shared instance (hardcoded) | The registry the chords are reserved in. Not injectable. |

