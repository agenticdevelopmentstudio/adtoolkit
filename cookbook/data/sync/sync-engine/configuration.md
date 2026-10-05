
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `deviceId` | string | required | Sent as the push request's deviceId on every push |
| `pullLimit` | integer | `500` | Limit passed to each pull request |
| `pushBatchSize` | integer | `100` | Max ops per push batch and per no-progress re-check |
| `baseBackoff` | duration (seconds) | `2` | Seconds for the first retry delay |
| `maxBackoff` | duration (seconds) | `3600` | Cap on any retry delay, in seconds |
| `hostResources` | optional list of resources | none | Absent accepts the whole manifest; set narrows the effective set to manifest ∩ hostResources |
| `store` | store contract implementation | required (construction) | Mirror, outbox, cursor and registrations |
| `transport` | transport contract implementation | required (construction) | Pull/push wire and credentials |
| trigger | trigger source implementation | none | Attached with `attach`; any number |
| `maxConsecutiveNoProgressPulls` | constant | `2` | Not configurable |
| `maxReconcileResyncsPerCycle` | constant | `3` | Not configurable |
| event buffer | constant | newest 256 | Not configurable |

No environment variables or settings keys are read.

