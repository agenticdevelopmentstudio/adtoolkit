
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| API client | injected dependency | same-origin client with base path `/api` | Resolves `/board` against the host's base path; a test double can be injected |
| Shared cache | injected dependency | none (required) | Holds the `["board"]` cache; callers sharing it share one board |
| Poll interval | constant (ms) | `60000` | Poll cadence |
| Read-clock staleness threshold | constant (ms) | `180000` | 3 × poll cadence |
| Data-clock stale-cycle multiplier | constant | `2` | Multiplier on the snapshot-staleness window for the data-clock window |
| Snapshot-staleness floor | constant (ms) | `300000` | Floor of the snapshot-staleness window, and the window used when `probeIntervalMs` is missing |
| Retry count | number | `1` | Retries before an error is reported |
| Client clock refresh interval | number (ms) | `30000` | Client clock refresh used for the read-clock check (default, not overridden by this logic) |
| `probeIntervalMs` | server-supplied field | — | Cadence that scales the data-clock window, taken from the board being judged |

