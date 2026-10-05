
`status-server-routes` is the HTTP surface of the status server: 17 route
modules under `packages/web/packages/status-server/src/routes/`, each a
factory that returns a `Hono` (or `OpenAPIHono`) sub-app mounted by the
top-level server assembly. Together they cover four bands: public
pre-authentication endpoints (`auth.ts`, `device.ts`'s public half, provider
webhooks in `hooks.ts`), authenticated read endpoints that assemble the
dashboard's live/status/snapshot/history/telemetry views (`reads.ts`,
`stream.ts`, `telemetry.ts`, `activity.ts`, `fleet.ts`, `badge.ts`), authenticated
write endpoints that mutate the monitored roster or the instance's
users/tokens (`config.ts`, `board.ts`'s reconcile route, `auto-configure.ts`,
`cron.ts`, `users.ts`, `tokens.ts`, `device.ts`'s approval half), and one
shared low-level helper (`read-body.ts`). None of these files render UI —
they are server-side request handlers whose contract is the JSON (or SSE, or
SVG) they emit, not a screen.

Route modules delegate policy to lower layers rather than re-implementing it:
persistence and atomic guards live behind the `Storage` port, roster-vs-board
folding lives in `reconcileBoardLedger`/`deriveBoard` (documented in the
sibling `status-server-board` recipe), and project-matching/wiring for
auto-configure lives in the external `@agentic-toolkit/deploy-platform/engine`
package. This recipe documents the route layer's own contract: what each
endpoint validates, what it returns, what authorization tier gates it, and
where its error/edge-case behavior is and isn't defined.

