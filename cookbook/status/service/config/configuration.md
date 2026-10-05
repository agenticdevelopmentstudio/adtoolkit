
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PORT` | env var | `3000` | TCP port the host serves the API on (`StatusConfig.port`). |
| `APP_VERSION` | env var | `'0.0.0'` | Reported in `/health` and the OpenAPI document. |
| `RAILWAY_GIT_COMMIT_SHA` | env var | `null` | Git commit the running build was cut from. |
| `PROBE_INTERVAL_SECONDS` | env var | `60` | Endpoint-probe cadence, seconds. |
| `DEPLOY_SYNC_SECONDS` | env var | `null` (derived: `max(300, probeIntervalSeconds × 5)`) | Explicit override of the deploy-sync cadence; must parse to a positive finite number or is ignored. |
| `CORS_ALLOWED_HOSTS` | env var, comma-separated | `[]` | Origins the external CORS middleware allows (host names, no scheme). |
| `MCP_ALLOWED_HOSTS` | env var, comma-separated | `[]` | Host names the external MCP endpoint accepts (DNS-rebinding guard). |
| `PEER_TOKEN` | env var | `''` | Shared secret a peer monitor presents to read `/snapshot`; empty disables the peer-read path. |
| `MONITOR_LABEL` | env var | `'this monitor'` | Base fleet-board label; environment-qualified unless already production or self-qualified. |
| `RAILWAY_ENVIRONMENT_NAME` | env var | `''` | Consulted only to qualify `monitorLabel`; not itself a `StatusConfig` field. |
| `AUTH_DISABLED` | env var | `false` (`'1'` enables) | Dev/e2e escape hatch; refused at boot when `NODE_ENV=production` (SEC-M5). |
| `COOKIE_INSECURE` | env var | `false` (`'1'` enables, meaning `cookieSecure=false`) | Drops the session cookie's `Secure` flag for local http; refused at boot when `NODE_ENV=production` (SEC-M5). |
| `ADMIN_EMAILS` | env var, comma-separated | `[]` | Emails auto-promoted to admin, lower-cased. |
| `PUBLIC_BASE_URL` | env var | `''` (fallback: `https://${RAILWAY_PUBLIC_DOMAIN}`) | Browser-facing origin for OAuth callbacks; one trailing slash stripped. |
| `RAILWAY_PUBLIC_DOMAIN` | env var | — | Railway-injected fallback for `PUBLIC_BASE_URL`. |
| `GITHUB_OAUTH_CLIENT_ID` / `GITHUB_OAUTH_CLIENT_SECRET` | env var | `''` / `''` | GitHub OAuth app credentials; empty means GitHub login is unconfigured (checked by `status-server-auth`, external). |
| `GITHUB_FETCH_TIMEOUT_MS` | env var | `null` (code default `8000`, applied externally) | Deadline for outbound GitHub API calls; must be a positive finite number or is ignored. |
| `VERCEL_WEBHOOK_SECRET` / `RAILWAY_WEBHOOK_SECRET` | env var | `null` / `null` | Inbound deploy-webhook secrets; `null` when that platform's webhook is not wired. |
| `HEARTBEAT_URL` | env var | `null` | Outbound heartbeat ping URL; `null` disables it. |
| `ALERT_WEBHOOK_URL` | env var | `null` | Outbound alert webhook URL; `null` disables alert posting. |
| `GLITCHTIP_PROJECTS` | env var, comma-separated | `null` (every project the org returns) | Allowlist of GlitchTip project slugs eligible to open a board Problem. |
| `STATUS_CREDENTIAL_NAMES` (12 names, listed under credential-name-list) | env vars, by name | `undefined` per name | Provider credentials looked up by name into `StatusConfig.credentials`. |
| `NODE_ENV` | env var | — | Consulted only by the SEC-M5 guard; not itself a `StatusConfig` field. |
| `seed` | injected `SeedRoster` (`AppDeps.seed`, external to these three files) | `[]` | The host's roster of sites `POST /config/seed` creates. |

