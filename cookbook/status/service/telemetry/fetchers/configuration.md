
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `env.GLITCHTIP_URL` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | GlitchTip instance base URL; trailing slashes are stripped before building the issues-endpoint URL. All three GlitchTip fields must be present or the fetcher no-ops. |
| `env.GLITCHTIP_API_TOKEN` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | Sent as `Authorization: Bearer` on the issues request. |
| `env.GLITCHTIP_ORG` | `string \| undefined` (`GlitchtipEnv` field) | caller-supplied | GlitchTip organization slug interpolated into the issues-endpoint path. |
| `TIMEOUT_MS` | `number` (module constant, `glitchtip.ts`) | `12_000` | Deadline for the single GlitchTip issues request, via `AbortController`. Not exported; not caller-configurable. |
| `PAGE_LIMIT` | `number` (exported module constant, `glitchtip.ts`) | `100` | Page size requested from GlitchTip and the threshold `complete-flag-by-page-size` compares the response length against. |
| `env.POSTHOG_HOST` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | PostHog project host; trailing slashes stripped before building the query-endpoint URL. All three PostHog fields must be present or the fetcher no-ops. |
| `env.POSTHOG_API_KEY` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | Sent as `Authorization: Bearer` on every HogQL query. |
| `env.POSTHOG_PROJECT_ID` | `string \| undefined` (`PosthogEnv` field) | caller-supplied | Interpolated into the HogQL query-endpoint path. |
| `METRICS` | `MetricSpec[]` (module constant, `posthog.ts`) | fixed 4-entry array (`pageviews`/`24h`, `visitors`/`24h`, `pageviews`/`7d`, `visitors`/`7d`) | Not exported; not caller-configurable. Defines every metric this file will ever query. |
| `QUERY_TIMEOUT_MS` | `number` (module constant, `posthog.ts`) | `10_000` | Deadline for each individual HogQL query, via its own `AbortController`. Not exported; not caller-configurable. |

