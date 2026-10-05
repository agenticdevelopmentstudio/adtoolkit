
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| label | text | none, required | Names the channel in log lines. |
| backoffs | list of nanosecond waits | at once, 0.5 s, 1.5 s | The wait before each attempt; its length is the attempt count. |

The push engine reads no environment variable or settings key of its own.

