
- **Decision**: keep the auto-configure matching/creation engine
  (`@agentic-toolkit/deploy-platform/engine`) HTTP-agnostic; the route
  talks to it only through the in-process `statusAdapter`.
  **Rationale**: the engine is reused outside the HTTP layer and stays
  independently testable against a fake `StatusAddApi` without spinning up
  a server.
  **Approved**: pending

- **Decision**: model webhook ownership as a three-state result
  (`owned`/`not-owned`/`unknown`) with `unknown` failing closed to 503,
  rather than a boolean.
  **Rationale**: collapsing "the roster read failed" into "not owned" would
  silently drop a legitimate deploy event during a storage outage; 503
  tells the provider to retry once storage recovers.
  **Approved**: pending

- **Decision**: coalesce concurrent reconcile passes in `hooksRoutes` with a
  single-flight-plus-queued-flag gate rather than letting each webhook
  trigger its own independent reconcile.
  **Rationale**: a burst of webhooks (a multi-service deploy) would
  otherwise fan out into redundant, overlapping board derivations; the
  queued-flag pattern still guarantees every arrival is covered by some
  pass.
  **Approved**: pending

- **Decision**: exclude error-type Problems from `/status/snapshot`'s
  public/anonymous-reachable response.
  **Rationale**: an error Problem's `name`/`detail` carry internal GlitchTip
  project identifiers and raw exception titles that should not be
  disclosed to anonymous or peer callers; this is treated as a decision to
  make deliberately, not an accident of omission.
  **Approved**: pending

- **Decision**: gate `auto-configure.ts` and `board.ts`'s reconcile route
  with `requireAdmin` per-route, while `config.ts`, `users.ts`, and
  `cron.ts` apply it blanket via `app.use('*', ...)`.
  **Rationale**: the former two sub-apps are mounted alongside other,
  non-admin routes at a shared base path; the latter three are entirely
  admin-only sub-apps, so a blanket gate is both correct and simpler there.
  **Approved**: pending

- **Decision**: let `DELETE /tokens/:id` bypass the `requireAdmin`
  middleware in favor of a hand-rolled `isAdmin || isSelf` check.
  **Rationale**: a token must be able to revoke itself as a kill switch
  regardless of its own role; `requireAdmin` alone cannot express "or is the
  target of the call," so the route intentionally does not use it here.
  **Approved**: pending

- **Decision**: leave `/hooks/cloudflare` unimplemented.
  **Rationale**: Cloudflare has no per-deploy webhook to receive, so a route
  would have nothing to verify or dispatch; the existing poll cycle already
  covers Cloudflare deploy status. Documented in source as approved by the
  project owner on 2026-06-26.
  **Approved**: pending

- **Decision**: let `POST /cron/refresh` await its triggered cycle while
  `POST /live/check` triggers its cycle detached (`runNowDetached`).
  **Rationale**: the cron endpoint is called by an external scheduler that
  wants confirmation the cycle ran; the manual "check now" button is
  called from a request a human is actively waiting on and should return
  immediately, with the scheduler's own single-flight covering overlap.
  **Approved**: pending

