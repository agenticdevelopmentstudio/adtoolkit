
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `qos` (parameter to `run`) | quality-of-service class | `userInitiated` | The background queue's priority class the closure is dispatched to. |
| `work` (parameter to `run`) | closure, throwing or non-throwing | none — required | The synchronous, thread-blocking closure to run off the cooperative pool. |
| `debounce` (parameter to construction) | duration | 1 second | How long a key stays quiet before its scheduled work runs. |
| `maximumRetryInterval` (parameter to construction) | duration | 30 seconds, floored at `debounce` | Ceiling on the exponential backoff applied after a failed attempt. |
| `onFailure` (parameter to construction) | callback | none | Called once per failed attempt with the key and the error; the debouncer itself never logs. |
| `work` (parameter to `schedule`) | asynchronous, failable closure | none — required, per key | The work to (re-)schedule for `key`, replacing whatever was previously scheduled for it. |
| `teardown` (parameter to `add`) | asynchronous, non-failable closure | none — required | The fire-and-forget teardown to start and track. |

None of the three utilities reads an environment variable or a settings key; every value they operate on arrives as a construction or call parameter.

