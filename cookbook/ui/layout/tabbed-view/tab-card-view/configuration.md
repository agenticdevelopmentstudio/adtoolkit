
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Stack depth | Integer | `1` | How far back in the stack this card is drawn; `0` means the front (selected) card. |
| Close callback | Optional callback, no input or output | `nil` | Called when the close control's action fires. |
| Context-menu provider | Optional callback taking the triggering input event and returning an optional menu | `nil` | Supplies the menu returned when a context menu is requested; falls back to the platform's default context menu when `nil` or when it returns `nil`. |

Replacing the status symbols takes a list of status-symbol values: a small,
immutable, thread-safe pairing of an icon name with an accessibility label.
Source defines one built-in value, Idle (accessibility label "Idle" — the
value tab-pane-039 exercises); callers may construct other values directly.
See Platform Notes for the concrete icon identifiers.

