
### Data shapes

- **deploy-project-shape**: A `DeployProject` MUST carry `platform` (string, as recorded on deploys: `vercel`, `railway` or `cloudflare-pages`), `projectName` (string), `environment` (string or null), `environments` (string array), `latestAt` (string or null), `deployCount` (number), `latestStatus` (string or null: `success`, `failed`, `building`, `queued` or `canceled`), `wired` (boolean), `ignored` (boolean), `domain` (string or null), `domains` (string array), `gitRepo`, `gitBranch`, `rootDirectory` and `framework` (each string or null).
- **environment-per-entry**: `environment` MUST name the deploy environment one entry represents for Railway (enumerated once per environment, such as production, staging or testing, each with its own domain) and MUST be null for Vercel and Cloudflare, whose environment is encoded in the project name.
- **wired-flag**: `wired` MUST be true when the project is already referenced by a monitored endpoint.
- **ignored-flag**: `ignored` MUST be true when an operator has exempted the project from the "unconfigured" warning.
- **domains-list**: `domains` MUST list every domain the project serves (canonical plus redirect aliases); for Cloudflare and Railway, which have one host, it is the single-element list of `domain`.
- **deploy-projects-response-shape**: A `DeployProjectsResponse` MUST carry `projects` (a `DeployProject` array) and MAY carry `verifiedPlatforms` (string array).
- **verified-platforms-meaning**: `verifiedPlatforms` MUST list only the platforms the enumeration listed live and completely; only a platform in this list proves, by a project's absence from `projects`, that the project is gone upstream.
- **verified-platforms-absent**: When a response omits `verifiedPlatforms` (a backend that predates the field), a consumer MUST treat every wiring as live.
- **unconfigured-response-shape**: An `UnconfiguredResponse` MUST carry `pending`, `addable` and `noDomain` (each a `DeployProject` array, the project axis) and `unconfiguredSites` (an array of `{ id: string; name: string }`, the endpoint axis).
- **response-cast-unvalidated**: Both read operations MUST return the parsed response body as the declared response type with no runtime shape validation; the server (the status-server `/deploy-projects` routes) owns the shape.

### The deploy-projects read

- **deploy-projects-path**: The deploy-projects read (given the API client) MUST request the path `/deploy-projects`.
- **deploy-projects-fresh-path**: The deploy-projects read, given `{ fresh: true }`, MUST request the path `/deploy-projects?fresh=1`.
- **deploy-projects-fresh-default**: When the fresh option is omitted, the deploy-projects read MUST send the non-fresh path.
- **deploy-projects-no-store**: The deploy-projects read MUST bypass any local HTTP response cache so the browser cache never serves the body.
- **deploy-projects-http-error**: When the response is not ok (status outside 200–299), the deploy-projects read MUST fail with an error whose message is `deploy-projects <status>` (for example `deploy-projects 502`).
- **deploy-projects-success**: When the response is ok, the deploy-projects read MUST resolve with the parsed response body.
- **deploy-projects-single-request**: The deploy-projects read MUST send exactly one request per call, with no retry, no timeout and no cancellation of its own.

### The unconfigured-partition read

- **unconfigured-path**: The unconfigured-partition read (given the API client) MUST request the path `/deploy-projects/unconfigured`.
- **unconfigured-fresh-path**: The unconfigured-partition read, given `{ fresh: true }`, MUST request the path `/deploy-projects/unconfigured?fresh=1`.
- **unconfigured-no-store**: The unconfigured-partition read MUST bypass any local HTTP response cache.
- **unconfigured-http-error**: When the response is not ok, the unconfigured-partition read MUST fail with an error whose message is `deploy-projects/unconfigured <status>`.
- **unconfigured-success**: When the response is ok, the unconfigured-partition read MUST resolve with the parsed response body.
- **unconfigured-single-request**: The unconfigured-partition read MUST send exactly one request per call, with no retry, no timeout and no cancellation of its own.

### Fresh-fetch latch

- **latch-initial-armed**: The shared latch `nextFetchIsFresh` MUST start armed (true) when the concept is first loaded, so the first cached-state fetch of a page load requests `?fresh=1`.
- **latch-arm**: The arming operation MUST set the latch to armed and produce no result.
- **latch-read-at-start**: The cached state's fetch MUST read the latch once, before issuing the request, and pass that value as `fresh` to the deploy-projects read.
- **latch-disarm-on-success**: The cached state's fetch MUST disarm the latch only after the deploy-projects read resolves successfully.
- **latch-kept-on-failure**: When the deploy-projects read fails, the latch MUST stay in its prior state, so a retry of a failed fresh fetch is again fresh.
- **latch-scope**: The latch MUST be shared by every instance of the cached state in the running process (one per page load), and it MUST NOT affect the unconfigured-partition read or direct callers of the deploy-projects read, which choose `fresh` explicitly.
- **latch-arm-during-flight**: Any fetch started after arming MUST request fresh data. A fetch that succeeds clears the arm latch unconditionally, so an arm made while a fetch is already in flight is cleared when that fetch succeeds and the next fetch does not request fresh data; no signal reports this.

### The cached state

- **hook-query-key**: The cached state MUST register its query under the cache key `["deploy-projects"]`.
- **hook-enabled-default**: The cached state read with no argument MUST be enabled.
- **hook-enabled-false**: The cached state read with `{ enabled: false }` MUST NOT run its fetch.
- **hook-stale-time**: The query MUST use a freshness window of 60,000 ms, so data younger than 60 seconds is served from the shared cache without a refetch on mount.
- **hook-client-source**: The cached state MUST obtain its status API client from the app's API context.
- **hook-return**: The cached state MUST return the query result unchanged, so failures from the deploy-projects read surface as the query's error and error status.
- **hook-retry-policy**: The cached state MUST NOT set its own retry option; retry count and backoff are the shared cache's host-supplied defaults.
- **client-only**: Deploy Projects State MUST run only in a live client execution context; it has no server-only or universal-rendering variant.
### Ordering and concurrency

- **single-threaded**: All latch reads and writes MUST happen on a single execution thread; interleaving occurs only across the wait for the network request.
- **dedup-by-query-key**: Concurrent readers of the cached state under one shared cache MUST share one in-flight request, as the cache dedupes by query key.

### Side effects

- **network-only-effect**: The concept's only side effects MUST be HTTP GET requests through the status API client and mutation of the shared latch; it MUST NOT write to storage, log, or emit analytics.

