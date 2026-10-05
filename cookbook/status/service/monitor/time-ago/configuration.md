
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `iso` | `string` | none — required positional argument | ISO-8601 timestamp string of the event being measured; passed to `new Date(iso).getTime()` with no validation of its format. |
| `nowMs` | `number` | none — required positional argument | The caller-supplied "current time" in epoch milliseconds, against which `iso` is compared; per the source's own doc comment, this is passed in rather than read from `Date.now()` internally "for testability." |

