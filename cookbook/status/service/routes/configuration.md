
| Name | Source file | Purpose |
|---|---|---|
| `storage: Storage` | most route factories | persistence port passed into every route factory |
| `config: StatusConfig` | config.ts, telemetry.ts, reads.ts, hooks.ts | webhook secrets, peer/self base URL, provider credentials |
| `scheduler?: Scheduler` | cron.ts, stream.ts | optional — `runNow`/`runNowDetached`; its absence 503s `POST /live/check` |
| `deps.errorsFetcher` / `deps.analyticsFetcher` | telemetry.ts | test-injection points overriding the default provider fetchers |
| `SeedRoster` | config.ts | roster consumed by `runSeed` for `POST /config/seed` |
| `MAX_ACTIVITY_ROWS` | activity.ts (imported) | default/clamp ceiling for `limit` |
| `MAX_CURSOR_MS = 8.64e15` | activity.ts | largest timestamp a cursor may carry |
| `DEVICE_TTL_MS = 900_000` | device.ts | device/user code grant lifetime (15 min) |
| `POLL_INTERVAL_SEC = 5` | device.ts | minimum seconds between token polls before `slow_down` |
| `TOKEN_TTL_MS = 2_592_000_000` | device.ts | minted device-flow token lifetime (30 days) |
| `LOG_TIMEOUT_MS = 25_000` | deploy-logs.ts | provider build-log fetch abort timeout |
| `HEARTBEAT_MS = 25_000` | stream.ts | SSE keep-alive ping interval |
| `MANUAL_MIN_MS = 3_000` | stream.ts | per-caller manual-check debounce floor |
| `OPENING_CACHE_MS = 1_500` | stream.ts | reuse window for a recent snapshot as the SSE opening frame |
| `STREAM_MAX_MS = 600_000` | stream.ts | forced SSE reconnect interval (10 min) |
| `CACHE_TTL_MS = 30_000` | telemetry.ts | single-flight cache TTL for `/telemetry` |
| `PROVIDER_READ_CACHE_MS = 30_000` | reads.ts | single-flight cache TTL for deploy-project enumeration |
| `MAX_DEPLOYS = 250` | reads.ts | cap on deployments assembled per snapshot |
| `RESPONSE_BUCKETS = 60` | reads.ts | default bucket count for response-time history |
| rate limits (`max: 10/5/30`) | auth.ts, device.ts | per-route request-rate ceilings via the `rateLimit` middleware |

