
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Injected API client (argument to `get`) | API client | none; required | The injected client that resolves relative paths against its base (default base `/api`) and performs the request |
| Active source (composition root) | telemetry-source adapter | live source | Which adapter the dashboard reads through; set to the persisted-source adapter to serve from the database |
| Endpoint paths | string literals | `/telemetry`; `/errors`, `/analytics` | Hard-coded in each source; not configurable |

