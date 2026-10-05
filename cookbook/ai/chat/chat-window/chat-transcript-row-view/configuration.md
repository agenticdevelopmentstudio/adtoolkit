
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `message` | Chat message data | (required) | The message this row displays; supplies role, attribution, delivery status, and timestamp |
| `maxBubbleWidth` | Number | (required) | Upper bound passed to the embedded bubble and to the failure label's wrap width; callers typically derive this per-row via the max-bubble-width calculation, but the initializer takes it as a plain parameter |
| `actions` | Callback bundle | (required) | Bundle of the row's four interaction callbacks: `onOpen`, `onJump`, `onToggleExpanded`, `onSelect` |
| `lineLimit` | Number (optional) | not set | How many lines of the message the bubble shows before truncating and offering to expand (forwarded to the chat bubble component) |
| `bubbleStyle` | Enum (`.speaker` / `.terminal`) | `.speaker` | Which shape the bubble is drawn in (forwarded to the chat bubble component; see its own recipe) |
| `isExpanded` | Boolean | `false` | Whether the row starts out showing the whole message rather than truncated |

