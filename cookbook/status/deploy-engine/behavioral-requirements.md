
### Canonicalization (`canon/index.ts`)

- **platform-name-canonicalization**: `platformCanon` MUST map the literal
  string `"cloudflare-pages"` to `"cloudflare"` and MUST return any other
  input string unchanged, and MUST return `""` when given `null` or
  `undefined`.
- **deploy-target-key-shape**: `deployTargetKey` MUST return `null` when
  `platformCanon(platform)` is empty or `project` is falsy, and otherwise
  MUST return the string `${canonicalPlatform}|${project}|${envSegment}`,
  where `envSegment` is `environment` lowercased (or `""` if `environment` is
  null/undefined) when the canonical platform is `"railway"`, and `""` for
  every other platform.
- **deploy-project-key-shape**: `deployProjectKey` MUST return
  `${platformCanon(platform)}|${project}` and MUST NOT incorporate an
  environment segment, so the key identifies a project's existence
  independent of which environment is being matched.
- **env-from-project-name**: `envFromProject` MUST return `"staging"` when
  `projectName` starts with `"staging."` or ends with `"-staging"`, MUST
  return `"testing"` when it starts with `"testing."` or ends with
  `"-testing"`, and MUST return `"production"` for every other input,
  including a project name that carries neither marker.
- **host-env-label**: `hostEnv` MUST strip one leading `www.` label from
  `host` before matching, MUST then match a leading label against
  `staging`, `testing`, `preview`, `prod`, or `production` followed by a
  dot, MUST normalize a `prod`/`production` match and a no-match result to
  `"production"`, MUST normalize a `preview` match to `"staging"`, and MUST
  otherwise return the matched label verbatim (`"staging"` or `"testing"`).
- **site-apex-collapsing**: `siteApex` MUST repeatedly strip a leading
  `www.` label and/or a leading env-marker label (`staging.`, `testing.`,
  `preview.`, `prod.`, `production.`) from `host`, in either order, until no
  further label of either kind can be stripped, and MUST stop stripping
  before the result would have fewer than two dot-separated labels (so
  `"staging.io"` returns `"staging.io"` and `"www.com"` returns `"www.com"`
  unchanged).
- **domain-family-provider-exclusion**: `domainFamily` MUST return `null`
  when `host` (case-folded, with one trailing dot stripped) contains no dot
  at all, and MUST also return `null` when `host` equals or ends with a dot
  followed by any of the fifteen fixed provider suffixes (`vercel.app`,
  `railway.app`, `pages.dev`, `workers.dev`, `netlify.app`, `onrender.com`,
  `fly.dev`, `herokuapp.com`, `github.io`, `web.app`, `firebaseapp.com`,
  `azurestaticapps.net`, `ondigitalocean.app`, `deno.dev`, `surge.sh`).
- **domain-family-registrable-domain**: For a `host` that is not excluded by
  **domain-family-provider-exclusion**, `domainFamily` MUST return the last
  three dot-separated labels when the host's last two labels form one of the
  seven fixed two-part TLDs (`co.uk`, `org.uk`, `ac.uk`, `com.au`, `co.nz`,
  `co.jp`, `com.br`), MUST otherwise return the last two labels, and MUST
  return the whole (lowercased) host unchanged when it has fewer labels than
  that count.
- **project-base-name-stripping**: `projectBaseName` MUST strip a leading
  `staging.` or `testing.` label and MUST strip a trailing `-production`,
  `-staging`, or `-testing` suffix from `projectName` (applying both strips
  in sequence; either, both, or neither may match), and MUST return the
  input unchanged when no marker of either spelling matches — the same two
  spellings `envFromProject` reads.
- **ep-host-normalization**: `epHost` MUST return the URL's `host` (hostname
  plus any port) when `url` parses as a URL, MUST fall back to the raw input
  string when it does not parse, and in both cases MUST lowercase the result
  and MUST strip a trailing `:<port>` suffix.
- **slugify-form**: `slugify` MUST lowercase and trim `s`, MUST collapse every
  run of characters outside `[a-z0-9]` to a single hyphen, and MUST trim any
  leading or trailing hyphen from the result.

### Cross-thread rate limiting (`cooldown/provider-cooldown.ts`)

- **cooldown-shared-buffer**: The cooldown registry MUST store one cooldown
  expiry per entry of the fixed `PROVIDERS` tuple (`vercel`, `railway`,
  `cloudflare`, `crunchy`) in a `BigInt64Array` backed by a
  `SharedArrayBuffer`, and `cooldownState` MUST return that buffer so a
  worker thread can be handed the same registry via `workerData` rather than
  starting an empty one of its own.
- **cooldown-worker-attach**: `attachCooldownState` MUST replace the
  module's live registry with a `BigInt64Array` view over a supplied
  `SharedArrayBuffer` when one is given, and MUST leave the existing
  registry untouched when the argument is `undefined`.
- **cooldown-retry-after-parsing**: `noteRateLimited`'s Retry-After parsing
  MUST treat a header that parses as a positive, finite number of seconds as
  that many milliseconds, MUST otherwise treat a header that parses as an
  HTTP date strictly after `now` as the millisecond delta to that date, and
  MUST treat every other value (absent, non-numeric non-date, a past or
  invalid date, zero or negative seconds) as unusable.
- **cooldown-default-and-cap**: `noteRateLimited` MUST use
  `DEFAULT_COOLDOWN_MS` (60000) as the cooldown length when Retry-After is
  unusable, and in every case MUST clamp the chosen length to at most
  `MAX_COOLDOWN_MS` (900000).
- **cooldown-unknown-provider-degrades**: `noteRateLimited` MUST NOT throw
  when `provider` is not one of the four fixed `PROVIDERS` entries; it MUST
  log via `console.error` and MUST return `now + ms` without writing to the
  shared registry.
- **cooldown-never-shortens**: `noteRateLimited` MUST compare the computed
  expiry against the slot's current value via `Atomics.load` and MUST write
  the new expiry via `Atomics.store` only when it is strictly later than the
  existing one, so a shorter cooldown computed after a longer one (from a
  burst of 429s, or a race with the other thread) never shortens the
  effective cooldown.
- **note-if-rate-limited-gate**: `noteIfRateLimited` MUST return `false`
  and MUST NOT call `noteRateLimited` when `res.status` is not exactly 429,
  and MUST return `true` after recording the cooldown (reading the
  `retry-after` response header) when it is 429.
- **rate-limited-until-lapse-clear**: `rateLimitedUntil` MUST return `null`
  for an unknown provider name, MUST return `null` when the stored expiry is
  `0`, MUST return `null` and MUST clear the slot to `0n` via `Atomics.store`
  when the stored expiry is at or before `now`, and MUST otherwise return
  the stored expiry.
- **cooldown-slot-scoped-by-provider**: Every read and write of the cooldown
  registry MUST be scoped to the single slot `PROVIDERS.indexOf(provider)`
  and MUST NOT read or mutate any other provider's slot.

### Configuration classification (`classify.ts`)

- **non-deploy-kind-set**: `endpointNeedsWiring` MUST return `false` for
  exactly the three kinds in `NON_DEPLOY_KINDS` (`health`, `custom`, `dns`)
  and MUST return `true` for every other kind string.
- **endpoint-config-status-precedence**: `endpointConfigStatus` MUST return
  `"configured"` when `endpointNeedsWiring(e.kind)` is `false`, MUST
  otherwise return `"configured"` when both `e.platform` and
  `e.deployProject` are truthy, MUST otherwise return `"ignored"` when
  `e.ignoreProjectWarning` is `true`, and MUST otherwise return
  `"unconfigured"` — in that precedence order, so a fully wired endpoint
  reads `"configured"` even when `ignoreProjectWarning` is also `true`.
- **endpoint-unconfigured-delegates**: `endpointUnconfigured` MUST return
  exactly `endpointConfigStatus(e) === "unconfigured"` and MUST NOT
  duplicate the classification logic.
- **project-status-precedence**: `projectStatus` MUST return `"monitored"`
  when `p.wired` is `true`, MUST otherwise return `"ignored"` when
  `p.ignored` is `true`, and MUST otherwise return `"unmonitored"`.
- **project-unconfigured-delegates**: `projectUnconfigured` MUST return
  exactly `projectStatus(p) === "unmonitored"`.
- **partition-pending-split**: `partitionPending` MUST place every project
  for which `projectUnconfigured` is `true` into `pending`, MUST further
  place the subset of `pending` with a truthy `domain` into `addable`, and
  MUST set `noDomain` to `pending.length - addable.length`.
- **compute-config-status-independent-axes**: `computeConfigStatus` MUST
  derive `unconfiguredSites` from `endpoints` via `endpointUnconfigured` and
  `unmonitoredProjects`/`addableProjects`/`noDomainProjects` from `projects`
  via `partitionPending`, independently of each other, and MUST set
  `counts.total` to exactly `counts.sites + counts.projects` where
  `counts.sites = unconfiguredSites.length` and
  `counts.projects = unmonitoredProjects.length`.
- **unmonitored-by-platform-keying**: `computeConfigStatus` MUST key
  `unmonitoredByPlatform` by `platformCanon(p.platform)` for each pending
  project `p`, incrementing the count for that canonical key, so a
  `cloudflare-pages` and a `cloudflare` project increment the same entry.

### Add planning (`plan.ts`)

- **explicit-environment-precedence**: `planAddProject` MUST use
  `project.environment` (trimmed; empty treated as absent) as the
  endpoint's environment when it is present, and MUST fall back to
  `hostEnv(domain)` when there is a domain or `envFromProject(projectName)`
  when there is none, only when no explicit environment was supplied.
- **placeholder-url-for-domainless**: `planAddProject` MUST use the fixed
  string `PLACEHOLDER_URL` (`"https://"`) as the plan's `url` when
  `project.domain` is absent, and MUST use `https://${domain}` otherwise.
- **exact-host-wiring**: When an endpoint exists whose `epHost` equals the
  project's domain, `endpointNeedsWiring(e.kind)` is `true`, and no such
  endpoint is currently wired to a different, still-live deploy project,
  `planAddProject` MUST return a `wire-endpoint` plan for that endpoint,
  preserving the endpoint's own `environment` over the derived one when the
  endpoint already has one set.
- **exact-host-conflict-vs-stale-repair**: When the exact-host endpoint is
  wired to a different deploy project, `planAddProject` MUST return a
  `conflict` plan when that other project is still live (per `opts
  .liveProjects`, or when no live-project index was supplied at all), and
  MUST otherwise (the named project is verified absent on its own platform)
  return a `wire-endpoint` plan carrying `replaces` (the retired project
  name) and `replacesPlatform` (that project's own canonical platform, not
  necessarily the platform being added).
- **exact-host-excludes-non-deploy-kinds**: A `health`/`custom`/`dns`
  endpoint sharing the exact host MUST NOT be treated as an exact-host match
  by **exact-host-wiring**; it falls through to apex/sibling matching.
- **apex-ownership-add-endpoint**: When no exact-host match exists but a
  wireable endpoint's `siteApex(epHost(...))` equals `siteApex(domain)`,
  `planAddProject` MUST return an `add-endpoint` plan onto that endpoint's
  site, preferring a wireable endpoint over a non-wireable one that also
  shares the apex.
- **apex-ownership-excluded-for-domainless**: `planAddProject` MUST NOT
  apply apex-ownership matching when the project has no domain (an empty
  apex must not "own" every endpoint whose URL fails to parse).
- **sibling-match-same-platform-and-base**: When no exact-host or apex match
  exists, `planAddProject` MUST match a project to a sibling site via an
  existing wireable endpoint whose `deployProject`'s `projectBaseName`
  equals this project's `projectBaseName` and whose canonical platform
  equals this project's canonical platform.
- **sibling-match-cross-platform-excluded**: A same-base-name project on a
  different canonical platform MUST NOT be matched as a sibling; it falls
  through to `new-site`.
- **sibling-env-conflict**: When a sibling site match is found but that
  site already has a different, wireable, still-relevant endpoint whose
  `environment` equals this project's derived environment and whose
  `deployProject` differs from this project's, `planAddProject` MUST return
  an `env-conflict` plan naming that endpoint and its project, MUST NOT
  relax this guard for a retired rival project (unlike the exact-host case),
  and MUST otherwise return an `add-endpoint` plan onto the sibling site.
- **new-site-fallback**: When none of exact-host, apex, or sibling matching
  applies, `planAddProject` MUST return a `new-site` plan whose `siteName`
  is `projectBaseName(deployProject)` and whose `siteSlug` is
  `slugify(siteName)` — the same base the sibling rule matches future
  projects against.
- **live-project-index-canonicalization**: `indexLiveProjects` MUST key
  `keys` by `deployProjectKey(platform, projectName)` for every supplied
  project and MUST canonicalize every entry of `verifiedPlatforms` via
  `platformCanon` before storing it in `platforms`.
- **stale-wiring-requires-verified-platform**: `planAddProject`'s
  `stillLive` check MUST treat an existing endpoint's wiring as live
  (conservative) whenever no `liveProjects` index was supplied, the endpoint
  has no `deployProject`, or the endpoint's own canonical platform is not a
  member of `liveProjects.platforms`; only when the platform IS verified
  MUST it check `liveProjects.keys` for that project's key.

### Auto-configure orchestration (`run.ts`)

- **apply-sequentially-order**: `applySequentially` MUST invoke `applyOne`
  for each item of `items` one at a time, in array order, and MUST NOT start
  the next item's `applyOne` call before the previous one has settled.
- **apply-sequentially-resilience**: `applySequentially` MUST catch any
  error thrown or rejection from `applyOne` for a given item, MUST push that
  item into `skipped` with the error's `message` (or its `String()` form
  when it is not an `Error`) as `reason`, and MUST proceed to the next item
  rather than rethrowing.
- **apply-sequentially-progress**: `applySequentially` MUST invoke
  `onProgress(done, total)`, when supplied, exactly once per item after that
  item's outcome (success or catch) has been recorded, with `total` fixed
  at `items.length` for the whole run.
- **family-group-immutability**: `Working.familyGroup`, once built by
  `indexFamilyGroups` at the start of `runAutoConfigure`, MUST NOT be
  mutated for the remainder of that run; a site created mid-run is filed
  using the map as it stood at the run's start.
- **family-group-split-is-null**: `indexFamilyGroups` MUST map a domain
  family to `null` when two different sites' groups both claim endpoints in
  that family, and MUST leave a family mapped to the single group when only
  one group's sites claim it.
- **group-for-new-site-fallback**: `groupForNewSite` MUST return
  `fallbackGroupId` when `domainFamily(host)` is `null` or when the family
  is present in `working.familyGroup` mapped to `null` or is absent from the
  map, and MUST otherwise return the mapped group id.
- **unique-site-identity-order**: `uniqueSiteIdentity` MUST try, in order,
  the base slug, then `slugify(host)` (only when `host` is non-empty), then
  `${base.slug}-2` through `${base.slug}-99`, returning the first candidate
  whose `${groupId}|${slug}` key is not in `taken` and whose slug is
  non-empty, and MUST return `base` unchanged (untried against any further
  variant) when `base.slug` is itself empty.
- **execute-add-conflict-and-env-conflict-skip**: `executeAdd` MUST turn a
  `conflict` or `env-conflict` plan into a `skipped` outcome carrying a
  human-readable, project-name-prefix-free reason string, and MUST NOT write
  to the API for either plan kind.
- **execute-add-wire-endpoint-reports-replacement**: `executeAdd` MUST call
  `api.updateEndpoint` for a `wire-endpoint` plan with the plan's `platform`,
  `deployProject`, and `environment`, MUST update the in-memory
  `working.endpoints` snapshot to match, and MUST attach a `note`
  describing what was replaced (naming `plan.replaces` and
  `plan.replacesPlatform`) exactly when the plan carried a `replaces` value.
- **execute-add-match-only-skips-creation**: `executeAdd` MUST return a
  `skipped` outcome with reason `"no site monitors this domain yet"` for an
  `add-endpoint` or `new-site` plan when `create` was not supplied, and MUST
  NOT call any creation API in that case.
- **execute-add-new-site-rollback**: When `create` is supplied and a
  `new-site` plan's `api.createEndpoint` call rejects after `api.createSite`
  already succeeded, `executeAdd` MUST call `api.deleteSite` for the
  just-created site as a best-effort rollback, MUST rethrow the original
  `createEndpoint` error (never the rollback's own outcome) regardless of
  whether the rollback itself succeeds or fails, and MUST remove the site's
  slug key from `working.takenSlugs` only when the rollback delete did not
  itself throw.
- **execute-add-new-site-group-note**: `executeAdd` MUST attach a `note` to
  a successful `new-site` creation naming the domain family and stating the
  site was filed under the family's existing group instead of the selected
  one, exactly when `groupForNewSite`'s result differs from
  `create.groupId`, and MUST attach no note when `create.forceGroup` is set
  or when the resolved group equals the selected one.
- **run-auto-configure-snapshot-build**: `runAutoConfigure` MUST fetch
  `api.listAllEndpoints()` and `api.listSites()` (in parallel, via
  `Promise.all`) exactly once at the start of the run and MUST seed
  `working.takenSlugs` from every fetched site's `${groupId}|${slug}`
  before applying any project.

### Endpoint-axis wiring (`run.ts`)

- **index-endpoint-wiring-ambiguous-is-null**: `indexEndpointWiring` MUST
  map a host to `null` when two different projects' domain lists both claim
  it (differing in canonical platform or project name), and MUST otherwise
  map it to that one project's `{ platform, deployProject }`.
- **index-endpoint-wiring-defensive-domains**: `indexEndpointWiring` MUST
  treat a project whose `domains` field is missing or nullish as
  contributing no host to the index rather than throwing.
- **wire-matching-endpoints-idempotent-target-selection**: `wireMatchingEndpoints`
  MUST select as targets only endpoints for which `endpointUnconfigured` is
  `true` and whose `epHost(e.url)` maps to a non-null entry in the index
  built by `indexEndpointWiring`, excluding already-wired, operator-ignored,
  infra-kind, and ambiguous-host endpoints.
- **wire-matching-endpoints-per-target-resilience**: `wireMatchingEndpoints`
  MUST call `api.updateEndpoint` once per target sequentially, MUST record a
  failure for one target in `skipped` without aborting the remaining
  targets, and MUST report `wired` as the count of calls that did not throw.

### Removal / claim axis (`run.ts`)

- **hostOmittedFromDomainLists-suffix-set**: `hostOmittedFromDomainLists`
  MUST return `true` for a host ending in `.vercel.app`, `.workers.dev`, or
  `.pages.dev` (the three `UNLISTED_PROVIDER_SUFFIXES`), and MUST return
  `false` for every other host, including a `*.up.railway.app` host.
- **claimed-by-nothing-requires-configured-platform**: `endpointsClaimedByNothing`
  MUST return an empty `doomed` list with a single `withheld` entry stating
  no deploy platform is configured when `evidence.configuredPlatforms` is
  empty, and MUST NOT examine any endpoint in that case.
- **claimed-by-nothing-candidate-filter**: `endpointsClaimedByNothing` MUST
  restrict removal candidates to endpoints for which `endpointNeedsWiring`
  is `true`, `e.ignoreProjectWarning` is not `true`, the URL parses to a
  non-empty host, and that host is not excluded by
  **hostOmittedFromDomainLists-suffix-set**.
- **claimed-by-nothing-fleet-overlap-guard**: `endpointsClaimedByNothing`
  MUST return an empty `doomed` list with a `withheld` entry describing a
  credential/scope change, rather than any doomed endpoints, when none of
  the candidate hosts appears (claimed or ambiguous) in the index built from
  `projects`.
- **claimed-by-nothing-wired-authority**: For a wired candidate,
  `endpointsClaimedByNothing` MUST judge it doomed only when its own
  canonical platform is in `evidence.verifiedPlatforms` and
  `deployProjectKey(platform, e.deployProject)` is absent from the live-
  project index built from `projects`; a platform absent from
  `verifiedPlatforms` MUST withhold judgement for every wired candidate on
  that platform rather than mark any of them doomed.
- **claimed-by-nothing-mass-deletion-guard**: `endpointsClaimedByNothing`
  MUST withhold judgement for an entire platform's wired candidates (marking
  none doomed) when every one of that platform's wired candidates would
  otherwise be judged gone, rather than doom all of them.
- **claimed-by-nothing-unwired-authority**: For an unwired candidate,
  `endpointsClaimedByNothing` MUST judge it doomed only when every
  canonical platform in `evidence.configuredPlatforms` also appears in
  `evidence.verifiedDomains`, and its host is absent (not merely ambiguous)
  from the wiring index; any configured platform missing from
  `verifiedDomains` MUST withhold judgement for every unwired candidate.
- **claimed-by-nothing-withheld-is-mandatory-signal**: `endpointsClaimedBynothing`'s
  callers MUST log every entry of the returned `withheld` array, because an
  empty `doomed` from a withheld pass and an empty `doomed` from a healthy
  fleet are opposite facts that the return shape alone does not distinguish
  without also inspecting `withheld`.

### Summarization (`run.ts`)

- **summarize-auto-configure-pluralization**: `summarizeAutoConfigure` MUST
  use the singular noun/verb form (`"its site"`, `"1 project"`) when the
  relevant count is exactly 1 and the plural form otherwise, for `added`,
  `created`, and `wired` independently.
- **summarize-auto-configure-nothing-vs-no-new-matches**: `summarizeAutoConfigure`
  MUST return the fixed sentence
  `"Nothing to match — every monitored site is already wired to its deploy project."`
  when `added`, `created`, and `wired` are all zero and `noDomain + skipped`
  is also zero, and MUST otherwise (still nothing added/created/wired, but
  some leftover) return a `"No new matches — …"` sentence naming the
  leftover count and its `noDomain`/`skipped` breakdown.
- **summarize-auto-configure-manual-detail**: `summarizeAutoConfigure` MUST
  append a parenthetical breaking out `noDomain` and `skipped` counts only
  when at least one of them is nonzero, and MUST omit the parenthetical
  entirely when both are zero.

### Builder site matching (`builder-match.ts`)

- **repo-tail-extraction**: `repoTail` MUST strip a trailing `.git` suffix
  from `gitRepo`, MUST split on `/` or `:`, MUST drop empty segments, and
  MUST return the last remaining segment, falling back to the `.git`-
  stripped string unchanged when no segment remains.
- **prod-domain-of-environment-gate**: `prodDomainOf` MUST return
  `project.domain` when `project.environment` is `null` or the literal
  string `"production"`, and MUST return `null` for any other environment
  value (a staging/testing entry never supplies a site's `prodUrl`).
- **plan-builder-site-match-order**: `planBuilderSite` MUST attempt, in
  order, a match by `rootDirectory === repoDir`, then by
  `epHost("https://" + domain) === epHost(site.prodUrl)`, then by
  `site.slug === slugify(projectBaseName(projectName))`, taking the first
  matching site and ignoring the rest.
- **plan-builder-site-fill-vs-skip**: For a matched site,
  `planBuilderSite` MUST return `"skip"` with reason `"already configured"`
  when the site already has a `prodUrl`, MUST return `"fill-prod-url"` when
  it does not and `prodDomainOf(project)` is non-null, and MUST return
  `"skip"` with reason `"no production domain to fill"` otherwise.
- **plan-builder-site-new-site-identity**: For an unmatched project with at
  least one of `rootDirectory`, `domain`, or `gitRepo` set, `planBuilderSite`
  MUST return a `"new-site"` plan whose `repoDir` is `rootDirectory`, else
  the `repoTail` of `gitRepo`, else `project.projectName`, whose `platform`
  is `platformCanon(project.platform)`, and whose `name`/`slug` are
  `projectBaseName(projectName)` and its `slugify`, respectively.
- **plan-builder-site-no-identity-skip**: `planBuilderSite` MUST return
  `"skip"` with reason `"no identity"` when `rootDirectory`, `domain`, and
  `gitRepo` are all absent.
- **run-builder-auto-configure-working-snapshot**: `runBuilderAutoConfigure`
  MUST carry a mutable `working` copy of `sites` forward through the
  sequential run (via the shared `applySequentially`) so a site created or
  updated for one project entry is visible to a later entry's match.
- **run-builder-auto-configure-creation-opt-in**: `runBuilderAutoConfigure`
  MUST return a `"skipped"` outcome with reason
  `"no group to create the site in"` for a `"new-site"` plan when `opts
  .create` is not supplied, and MUST NOT call `api.createSite` in that case.

### Cloudflare adapter (`providers/cloudflare.ts`)

- **cf-worker-scripts-error-shape**: `listWorkerScripts` MUST return
  `{ scripts: [...] }` on a successful, `success: true` response, and MUST
  otherwise return `{ error, unreachable }` where `unreachable` is `true`
  only when the `fetch` call itself threw (network/timeout/abort) and
  `false` for a non-OK HTTP response or a `success: false` body.
- **cf-worker-scripts-429-cooldown**: `listWorkerScripts` MUST call
  `noteRateLimited("cloudflare", ...)` with the response's `retry-after`
  header when the response status is 429, before returning its error
  result.
- **cf-custom-domains-null-on-any-failure**: `listWorkerCustomDomains` MUST
  return `null` — with no further signal to the caller — for a non-OK HTTP
  response of any status (including 429), a `success: false` body, or a
  thrown error, and MUST log via `console.error` only in the thrown-error
  case.
- **cf-custom-domains-hostname-lowercased**: `listWorkerCustomDomains` MUST
  lowercase every hostname key of the returned map and MUST omit any result
  entry whose `hostname` or `service` is missing or empty.
- **cf-canonical-host-by-worker**: `canonicalHostByWorker` MUST group the
  input host→service map by service (worker), MUST pick one host per worker
  via `pickCanonicalHost`, and MUST omit a worker from the output entirely
  when it has no hosts (which cannot occur for a worker present in the
  input map, since every entry has at least one host).
- **cf-account-resolution-order**: `resolveCfAccountId` MUST return, in
  order of preference, a non-empty trimmed `configuredId`; else a non-empty
  trimmed `CLOUDFLARE_ACCOUNT_ID` environment variable; else a cached
  discovered id for `token`; else, when the token's `/accounts` listing
  succeeds with exactly one account, that account's id (which it also
  caches); else `null`.
- **cf-account-cache-success-only**: `resolveCfAccountId` MUST cache a
  discovered account id in the process-lifetime `discoveredAccountByToken`
  map only on a successful, unambiguous (exactly one account) discovery, and
  MUST re-probe `/accounts` on every call following a `null`, zero-account,
  or multi-account result rather than caching that outcome.
- **cf-account-call-independent-timeouts**: `resolveCfAccountForConn` and
  `withResolvedCfAccount` MUST each create and dispose (via `.done()`) a
  fresh, independent `withTimeout(6_000)` window for the account-resolution
  step and, in `withResolvedCfAccount`, a second fresh 6-second window for
  the subsequent `onAccount` call, so a slow account probe cannot consume
  the downstream call's time budget.

### Host selection (`providers/host-pick.ts`)

- **compare-monitor-host-order**: `compareMonitorHost` MUST order two hosts
  first by ascending label count (`a.split(".").length`), then, for equal
  label counts, by whether the host has a `www.` prefix (unprefixed first),
  then by ascending string length, then alphabetically — in that fixed
  precedence — and MUST be a total order independent of input order.
- **pick-canonical-host-normalization**: `pickCanonicalHost` MUST trim and
  lowercase every candidate, MUST drop blank candidates before comparing,
  MUST return `null` when no non-blank candidate remains, and MUST
  otherwise return the least element under `compareMonitorHost`.

### Railway adapter (`providers/railway.ts`)

- **railway-gql-variables-not-interpolated**: `gqlPost` MUST pass every
  GraphQL variable through the request body's `variables` field and MUST
  NOT string-interpolate a caller-supplied value into the `query` text.
- **railway-gql-429-cooldown**: `gqlPost` MUST call
  `noteRateLimited("railway", ...)` with the response's `retry-after`
  header whenever the response status is 429, regardless of which GraphQL
  operation was being sent, before returning the response to its caller.
- **railway-list-projects-null-vs-empty**: `listRailwayProjects` MUST
  return `null` when the HTTP response is not OK, when the GraphQL response
  carries a non-empty `errors` array, or when the request throws (except
  that it MUST NOT log via `console.error` when the thrown error's
  associated `signal.aborted` is `true`), and MUST return `[]` (not `null`)
  when the request succeeds with zero projects.
- **railway-project-domains-per-environment-split**: `railwayProjectEnvironments`
  MUST group service-instance domains by lowercased environment name,
  MUST include both custom domains and `*.up.railway.app` provider domains
  in each environment's `domains` list (deduplicated and sorted), MUST omit
  an environment whose combined domain list is empty, and MUST pick each
  environment's representative `domain` by preferring a custom domain (via
  `pickCanonicalHost`) over a provider domain.
- **railway-env-rank-ordering**: `railwayProjectEnvironments`'s output MUST
  be sorted by `railwayEnvRank` (production = 0, staging = 1, testing = 2,
  anything else = 3) ascending, with entries of equal rank ordered
  alphabetically by environment name.

### Vercel adapter (`providers/vercel.ts`)

- **vercel-domain-cache-ttl**: `fetchProjectDomainList` MUST reuse a cached
  entry for `projectName` without a network call when the cached entry is
  less than `DOMAIN_CACHE_TTL_MS` (one hour) old, and MUST otherwise issue a
  fresh request.
- **vercel-domain-provenance-shape**: `fetchProjectDomains` MUST return
  `live: true` with the freshly fetched (and newly cached) domain list on a
  successful request, MUST return `live: false` with the STALE cached list
  (or `[]` when there is no prior cache) on a non-OK response or a thrown
  error, and MUST NOT let a stale-but-successful-looking cached list report
  `live: true` after a refresh attempt has failed.
- **vercel-domain-filtering**: `fetchProjectDomainList` MUST include a
  domain in the cached/returned list only when the API marked it `verified`
  and its name does not end in `.vercel.app`.
- **vercel-domain-fetch-self-timeout**: `fetchProjectDomainList` MUST bound
  its own fetch call with a 5-second `AbortSignal.timeout(5_000)`
  independent of any timeout the caller applies.

### Shared utilities

- **cached-single-flight-ttl-reuse**: `cachedSingleFlight`'s returned
  function MUST return the last cached value without calling `build` again
  when called with `fresh` falsy and the cache is younger than `ttlMs`.
- **cached-single-flight-dedup**: `cachedSingleFlight`'s returned function
  MUST route every concurrent call that misses the cache (or passes
  `fresh: true`) into the SAME in-flight `build()` promise while one is
  outstanding, rather than starting a second `build()` call.
- **cached-single-flight-failure-not-cached**: `cachedSingleFlight` MUST
  clear its in-flight reference when `build()` rejects (via `.finally`)
  without writing a `cached` entry, so the next call retries `build` rather
  than replaying the rejection or a stale value.
- **map-limit-order-preserving**: `mapLimit` MUST place each `fn(items[i])`
  result at index `i` of the returned array regardless of the order in
  which the bounded workers complete.
- **map-limit-bounded-concurrency**: `mapLimit` MUST run at most
  `Math.min(limit, items.length)` concurrent invocations of `fn` at any
  time.
- **with-timeout-abort-and-clear**: `withTimeout` MUST return an
  `AbortSignal` that fires after `ms` milliseconds via an internal
  `setTimeout`, and MUST expose a `done()` that clears that timer, for a
  caller to invoke once the operation it is timing completes (whether it
  finished or was aborted).

