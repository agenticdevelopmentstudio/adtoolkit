
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `message` | Chat message data | required | The message to render: its `text`, `role`, `timestamp`, and `isWorkOutput` drive every other requirement above (`isStreaming` and `delivery` are not read — see States) |
| `maxWidth` | Number | required | The bubble's maximum width — see **bubble-width-bound-by-max-width** |
| `style` | Enum (`.speaker` / `.terminal`) | `.speaker` | Which of the two visual shapes to draw — see **corner-radius-by-style**, **terminal-style-role-fill-override** |
| `showsInlineTimestamp` | Boolean | `true` | Whether the formatted timestamp trails the text — see **inline-timestamp-optional** |
| `isTextSelectable` | Boolean | `true` | Whether the message text can be selected/copied — see **text-selectability** |
| `lineLimit` | Number (optional) | not set | Maximum lines shown before offering to expand; when not set, never truncates — see **line-limit-truncation** |
| `fillsWidthWhenWrapped` | Boolean | `false` | Whether a bubble whose text wraps stretches to `maxWidth` rather than its measured width — see **fills-width-when-wrapped** |
| `isExpanded` | Boolean | `false` | Whether the bubble starts already showing everything it holds — see **expanded-state-relayout** |

