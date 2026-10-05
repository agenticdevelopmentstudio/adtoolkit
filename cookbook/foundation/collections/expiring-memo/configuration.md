
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| ttl | duration in seconds | none, required | How long an entry is served after it was stored. |
| capacity | positive integer | none, required | Keys held at once; storing past it drops the oldest. |

The memo reads no environment variable or settings key of its own.

