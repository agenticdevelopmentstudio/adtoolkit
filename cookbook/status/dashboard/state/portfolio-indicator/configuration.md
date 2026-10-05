
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| (none) | — | — | Portfolio Indicator takes no parameters. |
| `SNAPSHOT_STALE_FLOOR_MS` | number constant | `300000` | Floor of the snapshot stale window; also the window when the backend omits `probeIntervalMs`. |
| `snapshot.probeIntervalMs` | number, null, or absent (server-supplied) | treated as `0` | Probe cadence; the stale window is 5 times this, floored at `SNAPSHOT_STALE_FLOOR_MS`. |
| Board state | injected dependency | — | Supplies the board (or null); carries its own polling, retry and board staleness configuration. |
| Live Snapshot | injected dependency | — | Supplies `snapshot`, `offline` and `blind`; carries its own transport configuration. |
| Shared cache context and status API context | required context | — | Required by the two inputs; Portfolio Indicator must be used where they are available. |

