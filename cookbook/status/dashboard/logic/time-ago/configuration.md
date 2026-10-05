
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `iso` | `string` | none (required) | Timestamp of the event, parsed with `new Date(iso)`; not validated. |
| `nowMs` | `number` | none (required) | "Now" in epoch milliseconds, supplied by the caller (usually the `useNow` hook, which refreshes every 30 s by default). |

