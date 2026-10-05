
Construction options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `refreshInterval` | duration | required | How often this conversation is re-read; the feed's own cadence |
| `load` | loader | required | Reads this conversation, already narrowed to its session |
| `seed` | list of messages | empty | Rows the feed already holds for this session |
| `lineLimit` | integer or none | required | Lines shown per message before the rest is offered; none shows whole |
| `send` | sender or none | none | Types a line into the session; none disables the composer |

The component also exposes a refresh operation, and it inherits the
dismissible overlay's presentation and dismissal operations.

