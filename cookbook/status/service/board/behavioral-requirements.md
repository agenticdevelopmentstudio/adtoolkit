
### Target Keys (target-key.ts)

- **segment-escaping**: `escapeSegment` MUST replace every `%` with `%25`
  before replacing every `|` with `%7C` — escaping the escape character
  first is what keeps the mapping injective.
- **segment-unescaping**: `unescapeSegment` MUST invert `escapeSegment` in
  one left-to-right regex pass (matching `%25` or `%7C` and substituting
  `%` or `|` respectively), never as two sequential global replaces, so
  unescaping `%7C` cannot re-create a literal `%25` that then gets
  misread as a separator.
- **board-target-minting**: `boardTargetKey(platform, id, environment)`
  MUST return `null` when `platformCanon(platform)` is falsy or `id` is
  falsy, and otherwise MUST return `${canonicalPlatform}|${escapeSegment(id)}|${escapeSegment(env)}`
  — always exactly three pipe-separated segments.
- **railway-environment-segment**: `boardTargetKey` MUST populate the
  environment segment, lowercased, only when the canonical platform is
  `"railway"`; for every other platform the segment MUST be the empty
  string, so one non-Railway project collapses to one target regardless
  of environment.
- **board-target-parsing**: `parseBoardTarget` MUST return `null` unless
  the input splits on `|` into exactly three parts with a non-empty
  platform and a non-empty id, and otherwise MUST return
  `{ platform, id: unescapeSegment(id), environment: unescapeSegment(environment ?? "") }`.

### Ownership (ownership.ts)

- **deploy-identity**: `entryIdentity` MUST return the roster entry's
  `providerProjectId` when present, else its `projectName`.
- **deploy-ownership-gate**: a roster entry MUST own a deploy target or
  deploy project (via `rosterTargets`, `rosterDeployProjects`,
  `ownedDeployTarget`) only while it is `isActive`, has `monitorDeploys`
  on, and does not have `ignoreProjectWarning` set.
- **roster-target-indexing**: `rosterTargets` MUST index every
  deploy-owning roster entry twice — under `boardTargetKey` keyed by its
  provider id (when it has one) and under `boardTargetKey` keyed by its
  project name — so a Railway entry's index keys stay environment-scoped
  exactly as the target keys themselves are.
- **vanished-vercel-narrowing**: `rosterTargets` MUST compute
  `vanishedVercel` from `dropVanishedVercelProjects` applied to
  `rosterDeployProjects`' Vercel/Railway/Cloudflare name sets against the
  live Vercel project mirror, and MUST narrow nothing (return an empty
  `vanishedVercel`) when that mirror is empty or would vanish every owned
  Vercel project at once.
- **roster-entry-matching**: `matchRosterEntry` MUST try a provider-id
  match first and a project-name match second, and MUST reject (return
  `null` rather than the name match) when both the deploy row and the
  matched-by-name entry carry a `providerProjectId` and the two disagree.
- **owned-deploy-target-gate**: `ownedDeployTarget` MUST return `null` for
  a row that is not a real-environment deploy row (per
  `isRealEnvDeployRow`), for a Vercel row whose project name is in
  `vanishedVercel`, or for a row no roster entry owns and whose platform
  does not canonicalize to `"crunchy"`.
- **owned-deploy-environment**: `ownedDeployTarget` MUST derive its
  returned `env` by calling `deployEnv(d.platform, d.projectName,
  d.environment, d.branch)` on every row it accepts, never by caching a
  tier per target — the same project's older and newer rows MAY legitimately
  carry different tiers when its production branch was repointed.
- **crunchy-always-visible**: a deploy row whose platform canonicalizes to
  `"crunchy"` MUST be ownable (target minted from the row's own platform
  and project name) even when no roster entry claims it.
- **roster-deploy-projects-grain**: `rosterDeployProjects` MUST record
  both the provider-id and project-name spellings of every deploy-owning
  entry, bucketed by canonical platform and environment-free.
- **owns-deploy-project**: `ownsDeployProject` MUST return `true`
  unconditionally for a Crunchy row, and otherwise MUST return `true` only
  when the row's provider id or project name appears in the matching
  canonical-platform bucket `rosterDeployProjects` produced.

### Problem Derivation (derive-problems.ts)

- **platform-health-target-spelling**: `platformHealthTarget(source)` MUST
  mint `"platform-health|<source>"` (exactly two segments, no trailing
  pipe, never through `boardTargetKey`), and `parsePlatformHealthTarget`
  MUST return the source unvalidated against `IssueSource` when the
  target carries that prefix, else `null`.
- **deploy-verdict-collapse**: `collapseByTarget` MUST reduce multiple
  `DeployFact`s that resolve to one board target to a single row via
  `supersedes`, whose tie-break order is: greater `createdAtMs` wins;
  on a tie, the row carrying a `providerProjectId` wins; on a further
  tie, the greater `projectName` wins; on a final tie, the greater
  `environment` wins.
- **deploy-problem-judging**: `deployProblems` MUST judge a target
  `stuck` only from an in-flight row that is newer than (or the only row
  for) the target's standing concluded verdict and whose `combinedStatus`
  is `building` for at least `STUCK_DEPLOY_MS`; otherwise it MUST judge
  the target `failed` only when the standing concluded verdict's
  `combinedStatus` is bad (per `deployIsBad`); a target with neither MUST
  produce no Problem.
- **deploy-problem-fields**: a `deployProblems` row MUST set `source` to
  the judged row's raw (uncanonicalized) `platform`, `environment` to the
  logical tier `ownedDeployTarget` derived (never the row's raw
  `environment`), `detail` to the first line of the commit message when
  failed or to `"stuck ${status} · ${ageMinutes}m"` when stuck, and
  `branch`/`errorText` from the judged row (the wedged row when stuck, the
  failed row when failed).
- **endpoint-problem-debounce**: `endpointProblems`, via `probeConfirmed`,
  MUST treat a `"down"` endpoint as an immediate Problem and a
  `"degraded"` endpoint as a Problem only once
  `nowMs - badSinceMs >= DEGRADED_CONFIRM_MS`.
- **endpoint-problem-gate**: `endpointProblems` MUST judge only endpoints
  whose roster entry is `isActive` and has `monitorHttp` on; it MUST key
  the Problem's `target` on the endpoint's bare `endpointId`.
- **endpoint-problem-fields**: an endpoint Problem MUST set `severity` to
  `"critical"` when down and `"minor"` when degraded, `source` to `"dns"`
  when `dnsOk` is false and `"http"` otherwise, and MUST leave `branch`
  and `errorText` `null`.
- **platform-problem-debounce**: `platformProblems` MUST judge only a
  platform fact whose `configured` is true, whose `ok` is false, and whose
  `streak` is at least `PLATFORM_UNREACHABLE_POLLS`; a platform that is
  not configured, that is `ok`, or that is below the streak threshold MUST
  produce no Problem.
- **platform-problem-severity**: a platform Problem MUST always carry
  `severity: "minor"`, regardless of provider.
- **stale-prod-problem-suppression**: `staleProdProblems` MUST skip
  (produce no row for) a target already present in its `suppress` set
  argument, and it MUST NOT be passed the error-target suppress set by
  `deriveBoard` (error targets cannot collide with deploy targets).
- **stale-prod-vanish-narrowing**: `staleProdProblems` MUST skip a
  `StaleProdFact` whose `projectName` is in `vanishedVercel`, and MUST
  produce no row for a project no roster entry owns.
- **stale-prod-environment-and-severity**: `staleProdProblems` MUST derive
  `environment` via `deployEnv("vercel", projectName, environment, branch)`
  using the project's *configured* production branch (not any one
  deployment's branch), MUST set `severity` to `"major"` only when that
  derived environment is `"production"` (else `"minor"`), and for a
  non-production tier MUST rewrite the literal word `"production"` in
  `detail` to the derived tier name.
- **error-target-spelling**: `errorsTarget(project)` MUST mint
  `"errors|${escapeSegment(project)}"` (exactly two segments), and
  `parseErrorsTarget` MUST return the unescaped project when the target
  carries that prefix, else `null`.
- **error-problem-grouping**: `errorProblems` MUST open at most one
  Problem per GlitchTip project (never one per error group), and within a
  project MUST rank its issues by `byImpact` — occurrence `count`
  descending, ties broken by ascending `issueKey`.
- **error-problem-level-filter**: `errorProblems`, via `judgedError`, MUST
  judge only an `ErrorFact` whose `level` (lower-cased) is `"error"` or
  `"fatal"` (a `null` or other level is never judged) and, unless the
  error feed is frozen, whose `lastSeenMs` is non-null and within
  `ERROR_RECENT_MS` of `nowMs`.
- **error-feed-freeze**: `errorFeedFrozen` MUST report frozen exactly when
  the `"glitchtip"` platform fact is `configured` and not `ok`; while
  frozen, `judgedError` MUST suspend the recency test (still requiring the
  level filter) so already-counted rows keep being judged instead of
  aging out.
- **error-problem-severity**: an error Problem MUST be `severity: "major"`
  when any counted issue's level is `"fatal"`, else `"minor"`, and MUST
  never be `"critical"`.
- **error-problem-fields**: an error Problem's `detail` MUST read
  `"${count} unresolved error(s) · ${clippedTopTitle}"`, its `sourceUrl`
  MUST be the top-ranked issue's `permalink`, its `errorText` MUST be the
  five highest-impact issues (worst first) each rendered
  `"${count}× ${clippedTitle}"` and newline-joined, and its `branch`
  and `commit*` fields MUST be `null`.
- **error-problem-allowlist**: `errorProblems` and `monitoredTargets`
  MUST both gate a project through the same `allowedProject` check —
  every project when `facts.errorProjectAllowlist` is `null`, else only
  projects present in that list.
- **error-problem-onset**: `errorProblems` MUST date a project's observed
  onset from the earliest `firstSeenMs` among its counted issues, clamped
  to no earlier than `nowMs - ERROR_RECENT_MS`, falling back to `nowMs`
  when no counted issue carries a `firstSeenMs`.
- **error-problem-gate**: `errorProblems` MUST return an empty array
  whenever `facts.errorsConfigured` is false.
- **problem-since-continuity**: `problemSince` MUST return the earlier
  (via `Math.min`) of a target's recorded ledger `openedAtMs` (when one
  exists) and the newly observed onset for that Problem source, so a
  Problem's `since` never resets forward across successive failures of
  the same target.
- **monitored-targets-union**: `monitoredTargets` MUST include: every
  active roster entry's `endpointId` when `monitorHttp` is on; every
  active, non-vanished, `monitorDeploys`-on entry's minted deploy target;
  every `configured` platform's `platformHealthTarget`; when
  `errorsConfigured` is true, every allowed project's error target, every
  open ledger row whose target is an error target, and every windowed
  issue event whose target is an error target; and every target
  `ownedDeployTarget` resolves from `facts.deploys` and
  `facts.inFlightDeploys`.

### Activity Derivation (derive-activity.ts)

- **activity-row-ids**: `deployRowId(deploymentId, step)` MUST mint
  `"deploy:${deploymentId}:${step}"` and `issueRowId(event, step, atMs)`
  MUST mint `"issue:${event.target}:${step}:${atMs}:${event.id}"`; each id MUST NOT be built from a mutable field (target, `createdAtMs`,
  branch, or project name for a deploy row).
- **activity-union**: `deriveActivity` MUST emit the union of every
  `deployEvents` row at or after the effective floor (`fromMs` or
  `nowMs - ACTIVITY_WINDOW_MS`) and every `issueEvents` row opened or
  resolved at or after that floor, and MUST NOT treat Activity as the
  complement of the Problems list — a row that is also a current Problem
  still MUST appear.
- **activity-deploy-rows**: for one deploy event, `deriveActivity` MUST
  emit a `"build"` row only when `buildPhase` is non-null, and a
  `"deploy"` row only when `deployPhase` is not `"none"`; a Crunchy row
  (whose `buildPhase` is always `null`) MUST therefore emit only a
  `"deploy"` row.
- **activity-deploy-suppression**: `deriveActivity` MUST suppress an
  issue-opened row for a target only when the feed already carries a
  bad-toned (`buildTone === "bad"` or `deployTone === "bad"`) deploy row
  for that same target; a not-bad (e.g. `built`/`deploying`) deploy row
  MUST NOT suppress a `stale` or `stuck` issue on the same target.
- **activity-issue-gate**: `deriveActivity` MUST drop any issue event
  whose `target` is not in the monitored-targets set (the injected
  `monitoredIn`, or a freshly computed `monitoredTargets` when omitted).
- **activity-resolved-row-gate**: `deriveActivity` MUST emit a resolved
  Activity row for an issue only when `resolvedReason === "recovered"`;
  an `"unmonitored"` or `null` reason MUST emit no resolved row.
- **activity-kind-classification**: `issueKind` MUST classify an issue
  event as `"platform"` when its target parses as a platform-health or
  errors target, as `"probe"` when its `source` is `"http"` or `"dns"`,
  and as `"deploy"` for every other source.
- **activity-sort-and-cap**: `deriveActivity` MUST sort its rows
  oldest-first by `at`, breaking ties on ascending `id`, and MUST keep
  only the newest `cap` rows (default `MAX_ACTIVITY_ROWS`), trimming from
  the front (oldest) end.
- **indicator-derivation**: `indicatorFor` MUST return `"operational"`
  when `problems` is empty, `"outage"` when any problem's `severity` is
  `"critical"`, and `"degraded"` otherwise.
- **activity-page-cursor**: `pageActivity` MUST exclude, when a cursor is
  given, every row that does not sort strictly before the cursor's
  `(atMs, id)` pair (per `beforeCursor`); it MUST treat a cursor id from
  the retired `deploy:<target>:<step>:<atMs>:<deploymentId>` grammar
  (more than three colon-separated parts) as unable to disambiguate a tie
  and therefore serve the whole tie group at that instant.
- **activity-page-progress**: `pageActivity` MUST set `nextCursor` to the
  oldest row it kept (never the oldest row fetched); when it keeps
  nothing, it MUST step the cursor to `floorMs` when `floorMs` narrows
  progress (is older than the cursor, or equals it with a non-empty
  cursor id), else to `cursor.atMs - 1`, and it MUST return `nextCursor:
  null` only when `sourcesExhausted` is true and no row was trimmed from
  the sorted, cursor-filtered candidate set.

### The Fold (derive.ts)

- **board-fold-purity**: `deriveBoard(facts, nowMs)` MUST be a pure
  function — it MUST perform no IO, and calling it twice with the same
  `facts` and `nowMs` MUST produce a deep-equal `Board`.
- **board-problem-ordering**: `deriveBoard` MUST sort the combined
  Problems array by `byRecency` — ascending `since`, ties broken by
  ascending `target`.
- **board-data-clock**: `dataAsOf` MUST compute `Board.dataAsOfMs` as the
  maximum of every endpoint's `checkedAtMs` and every platform fact's
  `sampledAtMs` only, returning `null` when both lists are empty; it MUST
  NOT be moved by any deploy fact, ledger entry, or `StaleProdFact`.
- **board-index-reuse**: `deriveBoard` MUST build one `RosterIndex` (via
  `rosterTargets`) and one `monitoredTargets` result and thread both into
  every Problem-family function and into `deriveActivity`, rather than
  letting each rule re-derive its own.
- **board-stale-suppression**: `deriveBoard` MUST pass the set of
  `deployProblems` targets as the `suppress` argument to
  `staleProdProblems`, and MUST NOT pass a suppress set to
  `errorProblems`.
- **board-activity-window-published**: `deriveBoard` MUST set
  `Board.activityFromMs` to `nowMs - ACTIVITY_WINDOW_MS` — the same
  boundary `deriveActivity` cuts the feed at.

### Fact Reading (facts.ts)

- **deploy-outcome-binning**: `binByOutcome` MUST route a `DeployFact`
  into `concluded` when its `combinedStatus` is bad or resolving (per
  `deployIsBad`/`deployIsResolving`), into `inFlight` when its
  `combinedStatus` is `"building"` or `"queued"`, and into neither when
  `"canceled"` or `"unknown"`.
- **read-board-facts-composition**: `readBoardFacts` MUST assemble one
  `BoardFacts` snapshot for one `nowMs` from: the roster; the binned
  concluded/in-flight deploy rows; every deploy event since
  `nowMs - ACTIVITY_WINDOW_MS` bounded to owned projects; every issue
  event opened or resolved since that same floor; the open ledger rows;
  platform facts; stale-prod facts; the live Vercel project-name mirror;
  and error facts.
- **endpoint-facts-active-only**: `readEndpointFacts` MUST read the
  latest check only for the active roster's `endpointId`s (never the full
  health-check history), and MUST resolve a bad endpoint's `badSinceMs`
  from a persisted bad-run-onset query, falling back to that check's own
  `checkedAtMs` when the onset query returns nothing for it.
- **activity-page-reuse**: `readActivityPage` MUST reuse an injected
  `opts.base` (or read a fresh `readBoardFacts` result when omitted) for
  every field except `deployEvents`/`issueEvents`, which it MUST override
  from three separate cursor-bounded storage reads, and it MUST treat
  `floorMs` as `null` (sources exhausted) only when all three of those
  reads returned fewer rows than their limit.
- **activity-page-derivation**: `readActivityPage` MUST call
  `deriveActivity` with `fromMs: floorMs ?? 0` and `cap: Infinity` (never
  the board's 24-hour floor or `MAX_ACTIVITY_ROWS` cap), because the
  page's candidates are already bounded by the three storage-layer
  `limit`s.
- **activity-base-cache**: `createActivityPageReader` MUST share one
  `readBoardFacts` result across pages requested within
  `ACTIVITY_BASE_FACTS_CACHE_MS` of each other, via a per-instance
  `cachedSingleFlight`, and MUST create a fresh cache per call (never a
  module-level singleton) so tests and parallel instances do not share
  state.

### Ledger Reconciliation (reconcile.ts)

- **reconcile-composition**: `reconcileBoardLedger` MUST, in order: read
  facts via `readBoardFacts`, fold them via `deriveBoard`, then (unless
  skipped) write the resulting `Board` to the ledger via
  `applyBoardToLedger` and flush queued alerts via `flushAlerts`.
- **reconcile-idempotency**: `reconcileBoardLedger` MUST be safe to call
  repeatedly against the same underlying data — a second call in a row
  MUST resolve nothing the first call did not already resolve.
- **reconcile-skip-on-empty-roster**: `reconcileBoardLedger` MUST, when
  `opts.skipOnEmptyRoster` is true and the read roster is empty, return
  `{ board, opened: 0, updated: 0, resolved: 0, resolvedTargets: [],
  skipped: true }` without calling `applyBoardToLedger` or `flushAlerts`.
- **reconcile-alert-flush**: `reconcileBoardLedger` MUST flush alerts
  itself, on every non-skipped call, rather than depending on a caller's
  own cycle to flush them.

### Data Shapes and Invariants (types.ts)

- **board-problem-cardinality**: `Board.problems` MUST contain at most
  one `Problem` per distinct `target` value.
- **activity-row-id-stability**: `ActivityRow.id` MUST remain stable for
  the life of a rendered row — none of its components may be a field that
  a later read can correct in place.
- **resolved-reason-semantics**: `IssueEvent.resolvedReason` MUST
  distinguish `"recovered"` (the thing was observed working again) from
  `"unmonitored"` (it merely stopped being watched) from `null` (resolved
  before the reason column existed), and only a `"recovered"` close may
  ever produce a resolved Activity row.

