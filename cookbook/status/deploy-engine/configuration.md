
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `DEFAULT_COOLDOWN_MS` | `number` (module constant) | `60_000` | Cooldown length applied when a 429's Retry-After header is absent or unusable. |
| `MAX_COOLDOWN_MS` | `number` (module constant) | `900_000` | Upper clamp on any computed cooldown, including one derived from a Retry-After header. |
| `DOMAIN_CACHE_TTL_MS` | `number` (module constant, `vercel.ts`) | `3_600_000` (1 hour) | How long a Vercel project's fetched domain list is reused before a refresh is attempted. |
| `UNLISTED_PROVIDER_SUFFIXES` | `readonly string[]` (module constant, `run.ts`) | `[".vercel.app", ".workers.dev", ".pages.dev"]` | Provider-default host suffixes a removal pass must never judge absent-as-deleted. |
| `PLACEHOLDER_URL` | `string` (module constant, `plan.ts`) | `"https://"` | URL stamped on a new endpoint for a domain-less (e.g. Worker) project, pending operator fill-in. |
| `CLOUDFLARE_ACCOUNT_ID` | environment variable | none | Deploy-time fallback account id consulted by `resolveCfAccountId` when no per-connection account id is configured. |
| `conn.token` / `conn.accountId` | caller-supplied (`CfConn`) | none | Per-connection Cloudflare credential and optional configured account id. |
| `opts.create` (`CreateOpts` / `{ groupId }`) | caller-supplied | absent (match-only) | Opts a project-axis or builder-axis run into ALSO creating new sites/endpoints, and names the group new sites are filed under. |
| `opts.create.forceGroup` | `boolean` | `false` | Makes `groupId` authoritative, bypassing the domain-family group-inference rule. |
| `opts.liveProjects` (`LiveProjectIndex`) | caller-supplied | absent | This run's enumerated-project index, enabling stale-wiring repair; absent means every existing wiring is treated as live. |
| `limit` (`mapLimit`) | caller-supplied `number` | none (required) | Maximum concurrent `fn` invocations. |
| `ttlMs` (`cachedSingleFlight`) | caller-supplied `number` | none (required) | Cache lifetime in milliseconds for the wrapped `build` function. |
| `ms` (`withTimeout`) | caller-supplied `number` | none (required) | Milliseconds until the returned `AbortSignal` fires. |

