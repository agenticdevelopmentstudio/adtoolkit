
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| `open` | boolean | — (required) | Controls whether the outer dialog is shown. |
| `onClose` | callback, no arguments | — (required) | Invoked when Cancel, Escape, or the close control dismiss the outer dialog. |
| `author` | string | — (required) | Recorded as the `author` field of any note created during this session. |
| `notes` | list of note records | — (required) | The already-loaded notes; seeds, and conditionally re-seeds, the working list. |
| `onSave` | callback, receiving a list of `{ id?, content }` entries | — (required) | Invoked with the working list's id/content pairs when outer Save is activated. |
| `busy` | boolean | `false` | Disables the outer Save control while `true`; has no other effect. |

