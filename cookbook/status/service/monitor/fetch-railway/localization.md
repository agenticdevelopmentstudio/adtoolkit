
- **Data collected**: this file introduces one user-facing (details-pane-visible) hardcoded English string, `RAILWAY_NO_BUILD_TEXT`, persisted as a deploy's `error_text` by its caller (`enrich-deploy-errors.ts`, external) and surfaced to whoever views that deploy's details. It is not routed through any localization mechanism.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal string, no key) | `(no build logs — the deployment has no associated build)` | Persisted `error_text` / returned build-log text for a Railway deployment with no associated build, shown in the details pane and the `GET /deployments/:id/log` response. |

Every other string this file emits (`console.error` diagnostic lines) is developer/operator-facing in server logs, not end-user-facing, and is documented under Logging rather than here.

