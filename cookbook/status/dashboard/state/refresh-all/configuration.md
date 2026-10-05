
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Interval | number | `60000` | Milliseconds between automatic refreshes. Not validated. The board shell passes `60,000`. |
| Shared cache context | injected dependency | host-provided | The cache whose entries are refetched. It also owns retry, network policy and in-flight-restart behavior. |
| Live key (hard-coded) | string | `"live"` | First key element excluded from refresh. Not configurable. |

