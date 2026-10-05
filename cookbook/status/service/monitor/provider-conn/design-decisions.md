
- **Decision**: read provider connections and project metadata through the `Storage`/`StatusConfig` ports instead of calling the deploy-platform package's own DB-based helpers (`providerConnFromConfig(db)`, `enumerateDeployProjectsVerified(db)`) directly.
  **Rationale**: stated directly in the source's own module comment — these are "the storage-boundary replacements" for those two helpers, which the deploy-platform package "still ships for its OWN Db-holding consumers, but which status-server may no longer call now that `db` does not leave `src/libsql/`." Every remaining `status-server` site that needs a provider connection or a live enumeration goes through `providerConn`/`enumerateDeployProjects` instead, per that same comment.
  **Approved**: pending
- **Decision**: resolve each integration row's token through `config.secrets`, keyed by the row's own `tokenEnvVar` name, rather than reading `process.env` directly inside this file.
  **Rationale**: stated directly in the source's own doc comment on `providerConn` — "the host decides what a credential name means; this package never reads the environment." This keeps the credential source pluggable per host (an env-var host, or a future secrets-manager host) without changing this file.
  **Approved**: pending
- **Decision**: resolve `conn` and read `storage.deploy.listProjectMeta()` sequentially (two ordinary `await`s inside one object literal) rather than concurrently via `Promise.all`, unlike the DB-based `enumerateDeployProjectsVerified(db)` it replaces.
  **Rationale**: not stated as a deliberate tradeoff in an inline comment; demonstrated as a fact of the code, per enumerate-sequential-not-concurrent. Recorded here per source-fidelity as fact, not endorsement — a reader who assumes this replacement preserved the DB-based helper's concurrency would be wrong, and a port that wants the faster concurrent shape should note that divergence explicitly rather than silently matching this file's sequential order.
  **Approved**: pending

