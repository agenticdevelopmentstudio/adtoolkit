
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `generatedAt` | `string` (ISO 8601) | none (required) | The board read's own server timestamp, re-stamped on every read. |
| `nowMs` | `number` | none (required) | The client clock in epoch ms. The sole call site passes `useNow()`. |
| `dataAsOfMs` | `number \| null` | none (required) | The server-clock time of the board's newest underlying observation. `null` means no observation. |
| `probeIntervalMs` | `number \| null \| undefined` | `undefined`, which gives the 600 000 ms window | The backend's probe interval, read by the call site off the board being judged. |
| `BOARD_POLL_INTERVAL_MS` | constant | 60 000 | The board poll cadence, compiled in. |
| `BOARD_STALE_MS` | constant | 180 000 | The read-staleness threshold, compiled in. |
| `BOARD_DATA_STALE_CYCLES` | constant | 2 | The data-window multiplier, compiled in. |

The module reads no environment variables and no settings keys, and takes no injected dependencies. Its one import is `snapshotStaleMs` from `./snapshot-staleness`.

