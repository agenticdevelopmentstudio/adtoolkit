
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `VERCEL_API_TOKEN` | `string \| undefined` (`config.credentials`) | none — triggers warn no-op | Bearer token for `checkVercel`'s probe of `api.vercel.com/v2/user`. |
| `VERCEL_TEAM_ID` | `string \| undefined` (`config.credentials`) | none | When unset, `checkVercel` appends an advisory note to `detail` regardless of probe outcome; never itself sent on the request. |
| `CLOUDFLARE_API_TOKEN` | `string \| undefined` (`config.credentials`) | none — triggers warn no-op | Bearer token for account resolution and the Worker-scripts probe. |
| `CLOUDFLARE_ACCOUNT_ID` | `string \| undefined` (`config.credentials`) | none — auto-discovered via the token when unset | When unset and auto-discovery succeeds, the check still passes but as `"warn"` with an advisory `missingEnv`; when auto-discovery fails, the check is `"error"`. |
| `RAILWAY_API_TOKEN` | `string \| undefined` (`config.credentials`) | none — triggers warn no-op | Bearer token for `checkRailway`'s GraphQL `projects` query against `backboard.railway.app`; must be an account/team token, not a project-scoped one. |
| `GLITCHTIP_URL`, `GLITCHTIP_API_TOKEN`, `GLITCHTIP_ORG` | `string \| undefined` each (`config.credentials`) | none — all three required together | `checkGlitchtip` requires all three before probing; any subset missing names only the missing ones via `missingWarn`. |
| `POSTHOG_HOST`, `POSTHOG_API_KEY`, `POSTHOG_PROJECT_ID` | `string \| undefined` each (`config.credentials`) | none — all three required together | `checkPosthog` requires all three before probing; any subset missing names only the missing ones via `missingWarn`. |
| `nowMs` (parameter of `runIntegrationsCheck`) | `number \| undefined` | `Date.now()` | Forwarded only into `selfCheckStability.stabilize`; has no effect on `checkStatsFreshness`'s own staleness computation. |
| `TIMEOUT_MS` (module constant) | `number` | `6_000` | Per-attempt timeout for every `probe`'d network call and for Cloudflare's account-resolution window. |
| `CRON_STALE_MS` (module constant) | `number` | `180_000` | Age threshold (3 minutes) beyond which `checkStatsFreshness` reports `"error"` instead of `"ok"`. |
| `PROBE_RETRIES` (module constant) | `number` | `1` | Maximum number of retries `probe` performs after the first attempt. |
| `RETRY_BACKOFF_MS` (module constant) | `number` | `300` | Fixed pause `probe` waits before its one retry. |
| `CONFIRM_RUNS` (`self-check-stability.ts` constant) | `number` | `2` | Minimum consecutive failing runs before an unreachable-kind failure is confirmed. |
| `CONFIRM_WINDOW_MS` (`self-check-stability.ts` constant) | `number` | `90_000` | Minimum wall-clock span the failure streak must cover before confirmation. |
| `CORRELATED_MIN` (`self-check-stability.ts` constant) | `number` | `2` | Minimum simultaneously-confirmed providers before the correlated-connectivity downgrade applies. |

