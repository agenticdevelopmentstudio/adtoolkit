
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `onCapture` | Callback | none | Called for every chord captured while recording, with the captured shortcut value. |
| `onCancel` | Callback | none | Called when the user presses bare Escape while recording. |
| `onCommit` | Callback | none | Called when the user presses bare Return or keypad Enter while recording. |
| `onRecordingChanged` | Callback | none | Called when recording starts (click/focus) or stops (loses focus/the manual recording-stop operation). |
| `displayedShortcut` | Shortcut (optional) | none | The shortcut the bound command is already assigned to; shown when nothing is pending. |
| `pendingShortcut` | Shortcut (optional) | none | The chord captured but not yet saved; takes precedence over `displayedShortcut` when set. The component only reads this property to decide what to display — it never assigns or clears it itself. The caller sets it (typically from `onCapture`) and clears it once the edit is committed or abandoned. |
| `placeholder` | String | the literal `"Click to record"` | Shown when there is nothing pending, displayed, or being recorded. |

