
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `integrationPlatform` (parameter to `platformHealthSource`) | `string \| null` | none — caller-supplied per call | The `deploy_integrations.platform` free-text value the caller (`libsql/stores/config-store.ts`, external) already has on hand. |
| `status` (parameter to `httpIsBad`, `deployIsBad`, `deployIsStuck`, `deployIsResolving`) | `HealthStatus` / `DeployStatus` | none — caller-supplied per call | The already-derived health or combined deploy status (from `health.ts`'s `classify` / `deploy-status.ts`'s `combinedStatus`, both external) the caller wants judged. |
| `ageMs` (parameter to `deployIsStuck`) | `number` | none — caller-supplied per call | Milliseconds since the deploy row was created, computed by the caller (`board/derive-problems.ts`'s `deployProblems`, external) as `nowMs - createdAtMs`. |
| `prevStreak` (parameter to `nextPlatformStreak`) | `number` | none — caller-supplied per call | The consecutive-failure count persisted from the prior poll, read by the caller from `platform_health_state.consecutive_failures` (external). |
| `failing` (parameter to `nextPlatformStreak`) | `boolean` | none — caller-supplied per call | Whether this poll's provider check failed, computed by the caller as `configured && !reachable` (`libsql/stores/observation-store.ts`, external). |
| `threshold` (parameter to `nextPlatformStreak`) | `number` | `PLATFORM_UNREACHABLE_POLLS` (`2`) | The consecutive-failure count `bad` requires; every current caller omits it and takes the default. |
| `configured` (parameter to `dropVanishedVercelProjects`) | `ConfiguredDeployTargets` | none — required | The site-owned deploy targets per platform, built by the caller (`board/ownership.ts`'s `rosterTargets`, external) from the monitored roster. |
| `liveVercelProjects` (parameter to `dropVanishedVercelProjects`) | `ReadonlySet<string>` | none — required; pass an empty set to mean "no account mirror available" | The Vercel project names the caller read live from the account, which MUST be a COMPLETE read (per the function's own doc comment) or a truncated page walk will misread as mass deletion. |

