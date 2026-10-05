
This file and `self-check-stability.ts` use no localization mechanism; every `detail` string they produce is a hardcoded English literal returned in the `/integrations` API response and rendered on the integrations panel for any authenticated user — a user-facing string, not a server log line, per this recipe's authoring rules a fact to record, not a gap to excuse.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — `stats` ok | `persistent · <samples> samples across <services> services` | `checkStatsStore`, always |
| n/a — `cron` pending | `first poll pending — no checks yet` | `checkStatsFreshness`, no prior recorded check |
| n/a — `cron` stale | `stale — last <ageLabel> ago` | `checkStatsFreshness`, age beyond `CRON_STALE_MS` |
| n/a — `cron` fresh | `last check <ageLabel> ago` | `checkStatsFreshness`, age within `CRON_STALE_MS` |
| n/a — provider missing token | `<ENV_VAR> not set` | `checkVercel`/`checkCloudflare`/`checkRailway`, no configured credential |
| n/a — telemetry missing env | `<names, comma-joined> not set` | `missingWarn`, GlitchTip/PostHog missing one or more credentials |
| n/a — reachable | `reachable` (optionally suffixed) | Every provider's ok branch |
| n/a — HTTP 401 (Vercel) | `HTTP <status> — token invalid` | `checkVercel`, `status === 401` |
| n/a — Cloudflare account unresolved | `CLOUDFLARE_ACCOUNT_ID not set and could not auto-discover` | `checkCloudflare`, no resolvable account |
| n/a — Cloudflare account discovered | `reachable (<n> scripts; account auto-discovered — set CLOUDFLARE_ACCOUNT_ID to pin it)` | `checkCloudflare`, auto-discovered account |
| n/a — Railway not authorized | An explanatory sentence naming a revoked, invalid, or project-scoped token | `checkRailway`, GraphQL error message exactly `Not Authorized` |
| n/a — reachability helper invalid credential | `HTTP <status> — <token or key> invalid` | `reachability`, `status` 401 or 403 |
| n/a — recheck pending | `recheck pending — <original detail>` | `self-check-stability.ts`, an unconfirmed failure streak |
| n/a — connectivity | `<n> providers unreachable at once — likely monitor-side connectivity, not provider outages` | `self-check-stability.ts`, correlated downgrade |

