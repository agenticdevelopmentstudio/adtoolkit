
- **Data collected**: this module forwards the operator's own `VERCEL_API_TOKEN`
  and `VERCEL_TEAM_ID` (resolved from `env` or, via `providerConn`, from
  `config.secrets`) to `fetchVercelProductionStates`, and persists per-project
  metadata (`projectName`, `domain`, `gitRepo`, `gitBranch`, `rootDirectory`,
  `framework`) returned by that fetch. It collects nothing from, or about, an
  end user of the monitored product.
- **Storage**: the resolved token and team id are never persisted by this file
  itself — they exist only as call arguments for the duration of one refresh —
  while the project metadata rows they authorize fetching ARE persisted, as
  `deploy_project_meta` rows, which is this module's entire purpose.
- **Transmission**: this file makes no HTTP call itself; it hands the resolved
  token to `fetchVercelProductionStates`, which is what sends it to Vercel's own
  API over HTTPS.
- **Retention**: a project's metadata row is retained until either a later
  snapshot's eviction removes it (see `unconditional-upsert-on-nonempty-meta`
  and `eviction-diffs-live-set-against-stored-names`) or something outside this
  file deletes it directly; this module defines no separate TTL of its own —
  the source's own module comment states that "an erroneous eviction is
  repaired by the next cycle's upsert (5 minutes)," describing the monitor
  cycle's polling interval as the de facto correction window, not a retention
  policy enforced here.

