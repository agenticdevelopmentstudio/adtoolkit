
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `VERCEL_API_TOKEN` | `string \| undefined` (field of `env`) | none — required for a non-no-op poll | The Vercel API Bearer token. Absent or empty triggers the no-op branch (noop-missing-token). Read only from the `env` object passed in, never from `process.env` directly by this file. |
| `VERCEL_TEAM_ID` | `string \| undefined` (field of `env`) | none | The Vercel team id to scope project enumeration, the team-slug lookup, and every provider call to. When unset, calls omit `teamId` entirely and the slug fallback takes the first team the token can see. |
| `overallBudgetMs` | `number \| undefined` (field of `env`) | `18_000` (`PROJECTS_OVERALL_BUDGET_MS`) | The overall poll budget in milliseconds, counted from before the enumeration loop starts (deadline-computed-once). Deliberately under the caller's 20-second `guard` timeout (`PROVIDER_POLL_TIMEOUT_MS`, `sync.ts`, external) so this function's own partial-result path fires first. Overridable "for tests/tuning" per the source comment. |
| `metaOnly` | `boolean \| undefined` (field of `env`) | `false` | When `true`, fetches only the project list for callers reconciling `deploy_project_meta` (external); skips the deployment-window fetch depth, the deploy derivation, the blind-project backfill, and the team-slug lookup entirely, returning `states: []` and `deploys: []` unconditionally (not as a partial). |
| `callTimeoutMs` | `number \| undefined` (field of `env`) | `6_000` (`PROJECTS_CALL_TIMEOUT_MS`) | Per-page-request timeout in milliseconds, overridable "so a test can exercise the page retry in milliseconds instead of waiting out a 6s box," per the source comment. |
| `PROJECTS_CALL_ATTEMPTS` (module constant) | `number` | `2` | Fixed per-page retry count; not exposed on `env` and not configurable per call. |
| `LATEST_DEPLOYMENTS_DEPTH` (module constant) | `number` | `10` | Fixed `latestDeployments` query depth for a non-`metaOnly` call; not configurable per call. |
| `CONCLUSIVE_CALL_TIMEOUT_MS` (module constant) | `number` | `5_000` | Fixed per-project timeout for the blind-project backfill's `/v6/deployments` call; not configurable per call. |
| `TEAM_SLUG_CACHE_TTL_MS` (module constant) | `number` | `3_600_000` (1 hour) | Fixed memoization window for the resolved team slug; not configurable per call. |
| `MIN_SLUG_CALL_MS` (module constant) | `number` | `500` | Fixed minimum remaining-budget window below which a team-slug sub-call is skipped rather than issued; not configurable per call. |
| `DOMAIN_CACHE_TTL_MS` (module constant) | `number` | `3_600_000` (1 hour) | Fixed memoization window per project for the resolved custom-domain list; not configurable per call. |

