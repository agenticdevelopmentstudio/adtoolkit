
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `RAILWAY_API_TOKEN` | `string \| undefined` (field of `env`) | none — required for a non-no-op poll | The Railway API Bearer token, sent by the vendored `gqlPost` as `Authorization: Bearer <token>` on every GraphQL call. Absent or empty triggers the no-op branch (noop-missing-token). This file reads it only from the `env` object passed in, not from `process.env`. |
| `projects` | `readonly RailwayProject[] \| undefined` (field of `env`) | `[]` (via `env.projects ?? []`) | The configured fallback project list (`{ id, name }` pairs), used only when `listRailwayProjects` fails to enumerate live (fallback-to-configured-projects). The caller (`sync.ts`, external) passes `conn.railway.projects`, sourced from the DB integration config. |
| `overallBudgetMs` | `number \| undefined` (field of `env`) | `18_000` | The overall poll budget in milliseconds, counted from before the project-listing call starts (deadline-starts-before-listing). Per the source's own comment, deliberately shorter than the caller's `PROVIDER_POLL_TIMEOUT_MS` (20,000ms, `sync.ts`, external), and overridable "for tests/tuning." |
| `callTimeoutMs` | `number \| undefined` (field of `env`) | `6_000` (`RAILWAY_CALL_TIMEOUT_MS`) | The per-GraphQL-call time box, overridable so a test can exercise the retry "in milliseconds instead of waiting out a 6s box," per the source's own comment. |
| `RAILWAY_CALL_ATTEMPTS` (module constant) | `number` | `2` | Total attempts (one original plus one retry) for the project listing and for each project's poll, on our own timeout only. Not exposed on `env`. |
| `RAILWAY_PROJECT_CONCURRENCY` (module constant) | `number` | `5` | Fixed fan-out limit for per-project polls via `mapLimit`. Not exposed on `env`. |
| `RAILWAY_ENV_PAGE_SIZE` (module constant) | `number` | `200` | Pinned page size (the `first` variable) for the per-project `environments` query. Not exposed on `env`. |
| `RAILWAY_LOG_TAIL_LINES` (module constant) | `number` | `40` | Trailing line count `buildLogTail` keeps. Not exposed on `env`. |
| `RAILWAY_LOG_MAX_CHARS` (module constant) | `number` | `4_000` | Character cap `buildLogTail` applies to its joined tail. Not exposed on `env`. |
| `RAILWAY_LOG_FULL_LINES` (module constant) | `number` | `10_000` | The `limit` argument `fetchRailwayBuildLog` sends to the `buildLogs` query for the on-demand full read. Not exposed on `env`. |
| `RAILWAY_NO_BUILD_TEXT` (exported constant) | `string` | `(no build logs — the deployment has no associated build)` | The permanent placeholder both build-log fetchers return for a deployment Railway reports as never having had a build. |

