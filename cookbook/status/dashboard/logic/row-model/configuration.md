
| Option | Type | Default | Description |
|--------|------|---------|--------------|
| `nowMs` (used by the display adapter, the row-text function, the rows-text function, and the deploy-unconfirmed function) | number | none (required) | Epoch milliseconds used for relative time labels and the demotion clock; injected so the functions stay pure. |
| `probeIntervalMs` (used by the unconfirmed-window function and the deploy-unconfirmed function) | number or absent | absent, treated as 0 | The backend probe cadence (from the board's `probeIntervalMs`); the window is five times it, floored at 10 minutes. |
| the unconfirmed floor | constant number | `600000` | Floor of the unconfirmed window. |

There are no environment variables, settings keys or injected services.

