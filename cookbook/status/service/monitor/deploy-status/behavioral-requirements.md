
### Data Shape

- **deploy-status-values**: A deploy status MUST be exactly one of `"success"`, `"failed"`, `"building"`, `"queued"`, `"canceled"`, or `"unknown"`.
- **build-phase-values**: A build phase MUST be exactly one of `"queued"`, `"building"`, `"built"`, `"failed"`, `"canceled"`, or `"unknown"`.
- **deploy-phase-values**: A deploy phase MUST be exactly one of `"none"`, `"deploying"`, `"deployed"`, `"failed"`, or `"unknown"`.
- **phases-shape**: A phases pair MUST carry exactly two fields: a build phase, which may be absent, and a deploy phase.
- **build-phase-null-meaning**: An absent build phase MUST be produced, and only produced, by a provider mapper for a platform that reports no build lifecycle of its own — a platform that lists only already-live deployments is the documented example; the Crunchy Bridge phase mapper (Crunchy Bridge has no build/deploy CI lifecycle at all) is this module's own such mapper.
- **unknown-phase-terminal**: A build phase or deploy phase value of `"unknown"` MUST be treated as terminal — an in-flight phase the monitor could not re-confirm before its expiry window elapsed (handled external to this module) — and MUST NOT be treated as a good or bad verdict; it is, like `"canceled"`, the absence of a verdict, but unlike `"canceled"` it MUST NOT be read as a claim that the provider itself stopped the work, and fresh provider truth (a poll or by-id re-fetch, external to this module) MUST be free to overwrite it.

### In-Flight Vocabulary

- **in-flight-build-phases-list**: The in-flight build-phase list MUST be exactly the two-element list `["building", "queued"]`.
- **in-flight-deploy-phase-value**: The in-flight deploy-phase value MUST be exactly `"deploying"`.
- **is-in-flight-definition**: The in-flight check, given a build phase and a deploy phase, MUST return `true` if and only if the build phase is a member of the in-flight build-phase list OR the deploy phase equals the in-flight deploy-phase value; this is THE definition of "still in flight" — the row states that can still change, with every other combination terminal.
- **is-in-flight-null-safe**: The in-flight check MUST return `false` for an absent build phase when the deploy phase is not the in-flight deploy-phase value, because an absent build phase is never a member of the in-flight build-phase list.
- **in-flight-build-order**: The build-phase ordering MUST list `"queued"` before `"building"`, reflecting that a build enters the queue once and leaves it once, so `"building"` is strictly later than `"queued"` and nothing walks that back; the deploy phase MUST have no equivalent ordering, because `"deploying"` is its only in-flight value and so has nothing to be out of order with.

### SQL Predicate Builders

- **in-flight-sql-shape**: The in-flight SQL-fragment builder, given a column prefix, MUST return the SQL boolean expression `(<prefix>build_phase IN ('building', 'queued') OR <prefix>deploy_phase = 'deploying')`, interpolating only the fixed literals of the in-flight vocabulary — never a caller-supplied value — so this fragment can never drift from the in-flight check.
- **in-flight-sql-default-prefix**: The in-flight SQL-fragment builder called with no argument MUST default the prefix to `""` (the stored row); passing `"excluded."` MUST produce the identical expression shape addressed at an upsert's incoming row instead.
- **column-overwritable-sql-per-column**: The per-column overwritable-predicate builder, given a column name and a prefix, MUST return a predicate testing only the single named column (`build_phase` or `deploy_phase`) against its own in-flight values OR `'unknown'`, and MUST NOT reference the sibling column; this is deliberately per-column so a real verdict on one lifecycle keeps its protection when the sibling lifecycle is `unknown` or in flight, rather than a whole-row predicate stripping that protection the moment either lifecycle is unknown.
- **webhook-keeps-stored-verdict-guard**: The webhook-guard predicate builder, given a column name, MUST include the term `(<incoming column is in flight> AND NOT <stored column is overwritable per the per-column predicate>)`, so a late in-flight webhook event landing on a row whose named column already holds a settled verdict MUST NOT overwrite that column.
- **webhook-keeps-stored-backwards-guard**: For the `build_phase` column only, the webhook-guard predicate builder MUST also include one term per pair of build-phase-ordering positions where the incoming value is earlier and the stored value is later (i.e. `(excluded.build_phase = 'queued' AND build_phase = 'building')`), derived from the build-phase ordering rather than hand-listed; for the `deploy_phase` column it MUST produce no backwards-guard terms at all, because `"deploying"` is that column's only in-flight value.
- **webhook-keeps-stored-terminal-exempt**: An incoming event whose value for the named column is itself terminal (not in the in-flight build-phase list / not equal to the in-flight deploy-phase value) MUST NOT be blocked by either term of the webhook-guard predicate, because the verdict-guard term requires the incoming value to be in flight and the backwards-guard term only ever matches two in-flight build values; a terminal event is the provider's current truth, and a re-promotion back into flight (e.g. `built` → rolling out again) is a legitimate move this predicate MUST permit.
- **collapse-build-sql**: The build-phase collapse builder, given a terminal value, MUST return `CASE WHEN build_phase IN ('building', 'queued') THEN '<value>' ELSE build_phase END`, leaving a settled (non-in-flight) build phase unchanged.
- **collapse-deploy-sql**: The deploy-phase collapse builder, given a terminal value, MUST return `CASE WHEN deploy_phase = 'deploying' THEN '<value>' ELSE deploy_phase END`, leaving a settled deploy phase unchanged.
- **collapse-sql-evaluates-current-row**: Both collapse builders MUST be expressed as a SQL `CASE` evaluated against the row's column value at update time, not a value captured earlier by the caller; this means a concurrent write landing between an external candidate read and this update is never clobbered.

### Provider Phase Mappers — Vercel

- **vercel-ready-to-built**: The Vercel phase mapper MUST map a ready state of `"READY"` to a build phase of `"built"`.
- **vercel-error-to-failed**: The Vercel phase mapper MUST map a ready state of `"ERROR"` to a build phase of `"failed"`.
- **vercel-canceled-deleted-to-canceled**: The Vercel phase mapper MUST map a ready state of `"CANCELED"` or `"DELETED"` to a build phase of `"canceled"`.
- **vercel-queued-to-queued**: The Vercel phase mapper MUST map a ready state of `"QUEUED"` to a build phase of `"queued"`.
- **vercel-fallback-to-building**: The Vercel phase mapper MUST map every ready-state value not covered above — `BUILDING`, `INITIALIZING`, `BLOCKED`, or any other string — to a build phase of `"building"`, per the mapping's documented fallthrough set.
- **vercel-deploy-production-gated**: The Vercel phase mapper MUST leave the deploy phase at `"none"` unless the build phase resolved to `"built"` AND the target is `"production"`; a build that is `"built"` on a non-production target is staged — built but never promoted — so it MUST get no deploy entry at all.
- **vercel-deploy-substate-mapping**: When the build phase is `"built"` and the target is `"production"`, the Vercel phase mapper MUST map a ready substate of `"PROMOTED"` to a deploy phase of `"deployed"`, a ready substate of `"ROLLING"` to a deploy phase of `"deploying"`, and every other ready-substate value (including absent) to a deploy phase of `"none"`.

### Provider Phase Mappers — Railway

- **railway-building-initializing**: The Railway phase mapper MUST map status `"BUILDING"` or `"INITIALIZING"` to a build phase of `"building"` and a deploy phase of `"none"`.
- **railway-deploying**: The Railway phase mapper MUST map status `"DEPLOYING"` to a build phase of `"built"` and a deploy phase of `"deploying"`.
- **railway-success-crashed**: The Railway phase mapper MUST map status `"SUCCESS"` or `"CRASHED"` to a build phase of `"built"` and a deploy phase of `"deployed"`; this is deliberate — a runtime crash after a successful build and deploy is a health concern, not a deploy failure.
- **railway-failed**: The Railway phase mapper MUST map status `"FAILED"` to a build phase of `"failed"` and a deploy phase of `"none"`; Railway's status vocabulary cannot separate a build failure from a deploy failure, and treating it as a build failure is the documented choice because build failure is the common case.
- **railway-waiting-needsapproval**: The Railway phase mapper MUST map status `"WAITING"` or `"NEEDSAPPROVAL"` to a build phase of `"queued"` and a deploy phase of `"none"`.
- **railway-removed-skipped**: The Railway phase mapper MUST map status `"REMOVED"` or `"SKIPPED"` to a build phase of `"canceled"` and a deploy phase of `"none"`.
- **railway-unrecognized-fallback**: The Railway phase mapper MUST map every status value not covered by the six cases above to a build phase of `"building"` and a deploy phase of `"none"` (the mapper's own documented default case).

### Provider Phase Mapper — Crunchy Bridge

- **crunchy-no-build-lifecycle**: The Crunchy Bridge phase mapper MUST always return an absent build phase, because Crunchy Bridge clusters have no build/deploy CI lifecycle — health is the cluster state alone.
- **crunchy-bad-state-detection**: The Crunchy Bridge phase mapper MUST return a deploy phase of `"failed"` when the suspended flag is `true`, OR when the cluster state is `"failed"`, `"creation_failed"`, or `"suspended"` (the three documented bad states), and MUST return a deploy phase of `"deployed"` otherwise.
- **crunchy-healthy-default**: Every cluster-state value other than the three documented bad states — including `"ready"`, every documented routine/transient operation (`creating`, `restarting`, `resizing`, `resuming`, `starting`, `upgrading`, `restoring`, `finalizing`, `replaying`, `destroying`, `suspending`), an empty string, and any unrecognized future value — MUST map to a deploy phase of `"deployed"`; this is a deliberate, owner-chosen "quieter" model: routine maintenance MUST NOT page, and an unrecognized state MUST NOT be assumed bad.
- **crunchy-phases-terminal**: Both fields the Crunchy Bridge phase mapper returns MUST always be terminal (the build phase is always absent, never an in-flight build phase; the deploy phase is always `"failed"` or `"deployed"`, never `"deploying"` or `"unknown"`), so that a caller's stuck-deploy check (external to this module) never misfires on a Crunchy Bridge cluster's arbitrarily old creation time.

### Combined Status Derivation

- **combined-status-evaluation-order**: The combining function MUST evaluate its rules in exactly this order, as a sequence of early returns rather than independent conditions, because a phases pair can match more than one rule and only the first matched rule's result is correct: failed, then canceled, then unknown, then deployed, then deploying, then built, then queued, then the default.
- **combined-status-failed-precedence**: The combining function MUST return `"failed"` when the build phase is `"failed"` OR the deploy phase is `"failed"`, checked before every other rule, so a failure verdict on one lifecycle wins even when the other lifecycle is `"unknown"`.
- **combined-status-canceled**: The combining function MUST return `"canceled"` when the build phase is `"canceled"`, checked after failed and before unknown.
- **combined-status-unknown-precedence**: The combining function MUST return `"unknown"` when the build phase is `"unknown"` OR the deploy phase is `"unknown"`, checked before the in-flight (`"deploying"`) and built/queued fallthrough rules, so a row whose lifecycle expired unconfirmable MUST NOT re-read as `"building"`.
- **combined-status-deployed-success**: The combining function MUST return `"success"` when the deploy phase is `"deployed"`.
- **combined-status-deploying-building**: The combining function MUST return `"building"` when the deploy phase is `"deploying"`.
- **combined-status-built-staged-success**: The combining function MUST return `"success"` when the build phase is `"built"` and none of the preceding rules matched — this is a build with no separate deploy step (non-production or staged).
- **combined-status-queued**: The combining function MUST return `"queued"` when the build phase is `"queued"` and none of the preceding rules matched.
- **combined-status-default-building**: The combining function MUST return `"building"` for every remaining combination — a build phase of `"building"`, an absent build phase with no matching deploy-phase rule, or any other combination not covered above.

