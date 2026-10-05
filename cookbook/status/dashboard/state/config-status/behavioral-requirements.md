
### Query keys and invalidation

- **configure-data-key**: Config Status MUST expose `CONFIGURE_DATA_KEY` equal to the tuple `["configure-data"]`.
- **classification-key**: Config Status MUST expose `CONFIGURE_CLASSIFICATION_KEY` equal to the tuple `["configure-classification"]`.
- **invalidate-both**: `invalidateConfigQueries` MUST invalidate the query cached under `CONFIGURE_DATA_KEY` and the query cached under `CONFIGURE_CLASSIFICATION_KEY`, starting both invalidations together (in parallel).
- **invalidate-result**: `invalidateConfigQueries` MUST resolve once both invalidations have settled successfully, with no value.
- **invalidate-rejection**: If either invalidation fails, the failure MUST propagate as the result of `invalidateConfigQueries` (it combines the two invalidations with no partial-success handling).

### Roster query (`configure-data`)

- **roster-reads**: The roster query MUST issue exactly four reads in parallel — listing groups, sites, integrations and all endpoints — each through the injected status API client.
- **roster-shape**: The roster query MUST resolve to a `ConfigureData` object `{ groups, sites, integrations, endpoints }` whose four arrays are the four read results unchanged, in that field mapping.
- **roster-all-or-nothing**: If any one of the four roster reads fails, the roster query MUST fail as a whole (no partial `ConfigureData`), because the four reads are combined into one operation with no partial-success handling.
- **roster-private**: The roster query's underlying state MUST NOT be exposed on its own; Config Status is documented as "the one access point", so consumers read endpoints only through the shared status model.
- **roster-no-provider-dependency**: The roster query MUST NOT depend on the deploy-project classification; a classification failure MUST NOT prevent `configure` from being populated.

### Classification query (`configure-classification`)

- **classification-fetch**: The classification query MUST request the unconfigured partition with no options, so it requests `/deploy-projects/unconfigured` without `?fresh=1` and is served from the server route's shared 30-second provider cache (the cache itself is owned by the backend route).
- **classification-no-interval**: The classification query MUST NOT set an automatic refresh interval; it refetches on mount, on whatever refresh the host cache applies, and on explicit invalidation.
- **classification-http-error**: A non-2xx response MUST fail the classification query with an error whose message is `deploy-projects/unconfigured <status>` (for example `deploy-projects/unconfigured 502`).

### Enablement

- **enabled-default**: Config Status invoked with no argument MUST behave as if `enabled: true` were passed.
- **enabled-forwarded**: The `enabled` flag MUST be passed to both the roster query and the classification query.
- **enabled-false-no-fetch**: With `enabled: false`, this consumer's observation of the two queries MUST NOT trigger a fetch; any other enabled consumer of the same keys still drives the shared queries, and this consumer still reads whatever those queries have cached.

### Status model assembly

- **empty-until-both**: When either the roster data or the classification data is not yet available, `status` MUST be the constant `EMPTY_STATUS`: empty `unconfiguredSites`, `unmonitoredProjects` and `addableProjects`, `noDomainProjects` of `0`, an empty `unmonitoredByPlatform` map, and `counts` of `{ sites: 0, projects: 0, total: 0 }`.
- **unconfigured-sites-predicate**: `status.unconfiguredSites` MUST be the roster `endpoints` filtered by this app's `endpointUnconfigured` predicate, preserving roster order.
- **paused-fold**: The predicate MUST treat an endpoint with `isActive === false` as opted out exactly like `ignoreProjectWarning === true`, so a paused, unwired endpoint is NOT counted in `unconfiguredSites`; an endpoint whose `isActive` is undefined MUST NOT be treated as paused.
- **endpoint-classification**: Under that predicate an endpoint MUST count as unconfigured only when its `kind` is not one of `health`, `custom` or `dns`, it lacks a truthy `platform` or a truthy `deployProject`, and it is not opted out.
- **projects-from-server**: `status.unmonitoredProjects` MUST be the server's `unconfigured.pending` array as received, with no client-side re-classification.
- **addable-from-server**: `status.addableProjects` MUST be the server's `unconfigured.addable` array as received.
- **no-domain-count**: `status.noDomainProjects` MUST equal `unconfigured.noDomain.length` (a count, not the array).
- **server-sites-ignored**: The server's `unconfigured.unconfiguredSites` (`{id, name}` only) MUST NOT be used; the endpoint axis is derived locally because the banner renders each endpoint's url, site and environment, which the server's minimal shape omits.
- **by-platform-tally**: `status.unmonitoredByPlatform` MUST map each canonical platform key to the number of `unmonitoredProjects` with that platform, where the key is `platformCanon(p.platform)`: `"cloudflare-pages"` maps to `"cloudflare"`, `null`/`undefined` maps to `""`, and every other value maps to itself.
- **counts**: `status.counts.sites` MUST equal `unconfiguredSites.length`, `status.counts.projects` MUST equal `unmonitoredProjects.length`, and `status.counts.total` MUST equal their sum.
- **memoized-status**: `status` MUST be recomputed only when the roster data or the classification data actually changes; the same pair of data MUST yield the same `status` value across repeated reads.

### Return value

- **return-shape**: Config Status MUST return `{ status, configure, isLoading, error, refetch }`.
- **configure-raw**: `configure` MUST be the roster query's data, not yet available until the first roster load resolves.
- **is-loading-rosters-only**: `isLoading` MUST reflect only the roster query's loading state; a pending or failed classification MUST NOT hold `isLoading` true.
- **error-precedence**: `error` MUST be the roster query's error when it is non-nullish, otherwise the classification query's error (roster-first order).
- **error-classification-reported**: When only the classification query has failed, `error` MUST be that failure, so a dead scan is never read as "zero gaps / all clear".
- **error-single-slot**: When both queries have failed, `error` MUST carry only the roster error; the classification error is not surfaced through this result.
- **refetch-both**: `refetch()` MUST refetch the roster query and the classification query in parallel and resolve with both results.
- **refetch-stable**: The `refetch` function's identity MUST change only when either underlying query's refetch identity changes.

### Caching, concurrency and side effects

- **shared-cache**: Multiple consumers reading Config Status under one shared cache MUST share the two cached queries; additional consumers MUST NOT cause additional fetches beyond the cache's own deduplication.
- **side-effects**: Config Status's only side effects MUST be the network reads made through the status API client (four roster reads and one classification read per query run); it MUST NOT write storage, log, or mutate server state.
- **no-timeout-no-cancel**: Config Status MUST NOT impose its own timeout, retry policy or cancellation on either query; those come from the host cache's defaults and from the status API client.
- **client-only**: Configuration Status State MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

