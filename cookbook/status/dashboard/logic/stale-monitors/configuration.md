
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `services` | `readonly LiveServiceDTO[]` | none (required) | The live snapshot's services. The banner passes `store.snapshot?.services ?? []`. |
| `nowMs` | `number` | none (required) | Reference time in epoch ms. The banner passes the client clock floored to the day. |
| `thresholdMs` | `number` | `STALE_MONITOR_MS` | Minimum continuous down time before a monitor is offered. |
| `STALE_MONITOR_MS` | constant | 604 800 000 (7 days) | Compiled-in default threshold. |

The module reads no environment variables and no settings keys, and takes no injected dependencies. Its only import is the `LiveServiceDTO` type from `./live-types`.

