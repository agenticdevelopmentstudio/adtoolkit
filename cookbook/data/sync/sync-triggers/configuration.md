
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PeriodicTriggerSource.init(interval:)` | `TimeInterval` (seconds) | none (required) | Delay before the first tick and between successive ticks |
| `ConnectivityTriggerSource.init(queue:)` | serial execution queue | new serial queue labelled `ConnectivityTriggerSource` | Queue on which path updates are delivered and the transition flag is updated |
| `ManualTriggerSource.fire(_:)` | `SyncKickReason` | none (required) | The reason to yield to the consumer |

No environment variables, settings keys, or other injected dependencies are read.

