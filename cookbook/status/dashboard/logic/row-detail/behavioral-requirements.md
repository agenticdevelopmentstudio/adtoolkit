
### Data shapes

- **row-input-shape**: The detail-building function MUST accept a row with these fields (named as in [Status Row Model](adtoolkit://cookbook/status/dashboard/logic/row-model)): `key`, `source`, `platform` (string or absent), `name`, `environment` (string or absent), `statusWord`, `tone` (one of `good`, `bad`, `progress`, `neutral`, `stale`), `sha`, `commitUrl`, `message`, `detail`, `at` (an ISO timestamp), `sourceUrl`, `liveUrl`, plus the optional `commitBody`, `statusCode`, `responseTimeMs`, `lastCheckedAt`, `downSince`, `branch` and `errorText`.
- **row-detail-shape**: The row detail MUST hold exactly these fields: `title` (a string), and the following, each nullable: `titleUrl`, `environment`, `platformText`, `platformLink`, `problem`, `problemLink`, `statusCode` (a number or null), `responseTime`, `branch`, `since`, `lastChecked`, `sha`, `commitSubject`, `commitUrl`, `commitBody`, `errorText`, and `deployOutcome` (one of `success`, `failed`, or null).
- **optional-fields-null**: Every optional row field that is absent MUST become `null` in the row detail. This covers `statusCode`, `branch`, `lastChecked`, `commitBody` and `errorText`.

### The detail-building function: row classification

- **endpoint-classification**: A row MUST be treated as an endpoint row when its `platform` is exactly `"http"` or `"dns"`, and as a deploy row otherwise.
- **resolved-classification**: A row MUST be treated as resolved when its `statusWord` starts with the character `[`, as in `"[deploy failed] resolved"`.
- **platform-name**: The platform name MUST be the platform label (see Deploy Display) of the row's platform, lower-cased, when the row is not an endpoint, the platform is truthy, and the row is not resolved. Otherwise it MUST be absent. For example, `vercel` yields `vercel` and `cloudflare-pages` yields `cloudflare`.

### The detail-building function: title and links

- **endpoint-title-url**: For an endpoint row, `titleUrl` MUST be the row's `liveUrl`, falling back to `sourceUrl`, then `null`. The documented reasoning is "an endpoint IS its checked url".
- **deploy-title-url**: For a deploy row, `titleUrl` MUST be the row's `sourceUrl`, falling back to `liveUrl`, then `null`. The documented reasoning is "a deploy's title links to its deployment page".
- **endpoint-title-host**: For an endpoint row with a truthy `titleUrl`, `title` MUST be the host of `titleUrl`, via the host-extraction helper.
- **title-name-fallback**: For a deploy row, or an endpoint row whose `titleUrl` is null or empty, `title` MUST be the row's `name`.
- **platform-text**: `platformText` MUST be the row's `statusWord` followed by the literal text `" on "` followed by the platform name, when a platform name exists (for example `built on vercel`), and `null` otherwise. Endpoint rows and resolved rows therefore get `null`.
- **platform-link**: `platformLink` MUST be the row's `sourceUrl` when a platform name exists, and `null` otherwise. Only the specific deployment URL is stored, so "platform" links to the deployment page.

### The detail-building function: problem

- **problem-dedupe**: `problem` MUST be the row's `detail` when `detail` is truthy and differs from `message`. It MUST be `null` when `detail` is null, empty, or equal to `message`. Deploy-status issues set `detail` to the commit's first line, which the commit field already shows.
- **problem-link**: `problemLink` MUST be the row's `sourceUrl` when `problem` is non-null, and `null` otherwise.

### The detail-building function: diagnostics and commit

- **environment-passthrough**: `environment` MUST equal the row's `environment`.
- **status-code**: `statusCode` MUST equal the row's `statusCode`, or `null` when it is absent.
- **response-time-format**: `responseTime` MUST be the row's `responseTimeMs` followed by the literal text `"ms"` (for example `1200ms`) when `responseTimeMs` is neither null nor absent, and `null` otherwise. A value of `0` yields `0ms`.
- **branch**: `branch` MUST equal the row's `branch`, or `null` when it is absent.
- **since-precedence**: `since` MUST be the row's `downSince`, falling back to `at`, then `null`. The server-truth down-since wins so "the pane always shows WHEN, absolute".
- **last-checked**: `lastChecked` MUST equal the row's `lastCheckedAt`, or `null` when it is absent.
- **commit-fields**: `sha` MUST equal the row's `sha`, `commitSubject` MUST equal the row's `message`, and `commitUrl` MUST equal the row's `commitUrl`, each copied unchanged.
- **commit-body**: `commitBody` MUST equal the row's `commitBody`, or `null` when it is absent. It holds the full commit message, subject included.
- **error-text**: `errorText` MUST equal the row's `errorText` verbatim, or `null` when it is absent. It is the provider's build failure reason and may be multi-line.
- **status-word-as-given**: The status word used in `platformText` MUST be the row's `statusWord` unchanged. The function applies no client-side freshness demotion and takes no clock argument.

### The detail-building function: deploy outcome

- **deploy-outcome-failed**: `deployOutcome` MUST be `"failed"` when a platform name exists, the row's platform is not in the non-deploy platform set, and the row's tone is `"bad"`.
- **deploy-outcome-success**: `deployOutcome` MUST be `"success"` under the same conditions when the row's tone is `"good"`.
- **deploy-outcome-unsettled**: `deployOutcome` MUST be `null` when the row's tone is `"progress"`, `"neutral"` or `"stale"`. In-flight (progress) and canceled (neutral) rows stay null.
- **deploy-outcome-no-platform**: `deployOutcome` MUST be `null` for endpoint rows, resolved rows, and rows whose platform is null or empty.
- **non-deploy-platforms**: `deployOutcome` MUST be `null` when the row's platform is `"crunchy"` or `"glitchtip"`, whatever the tone. Rows on those platforms report database-cluster health or application errors mapped onto deploy phases, so a "build / deploy FAILED" headline would name an event that did not happen. The set is explicit because the platform name is truthy for every registered source.

### The serialization function

- **text-line-format**: Each emitted field MUST be one line of the form `<label>: <value>`, and lines MUST be joined with a single line feed and no trailing newline.
- **text-populated-only**: A field MUST be emitted only when its value is neither null, absent, nor the empty string. A numeric `0` is emitted.
- **text-field-order**: The labeled lines MUST appear in this order, each only when populated: `endpoint` (from `title`), `url` (from `titleUrl`), `environment`, `platform` (from `platformText`), `problem`, `http status` (from `statusCode`), `response` (from `responseTime`), `branch`, `since`, `last check` (from `lastChecked`), `commit`, `commit url`, `link`.
- **text-endpoint-label**: The `title` MUST be labeled `endpoint` for every row, deploy rows included.
- **text-url-distinct**: The `url` line MUST be emitted only when `titleUrl` is truthy and differs from `title`.
- **text-commit-line**: The `commit` line MUST be emitted when `sha` or `commitSubject` is truthy. Its value MUST be the truthy ones among `sha` and `commitSubject`, in that order, joined by one space.
- **text-link-precedence**: The `link` line MUST carry `platformLink`, falling back to `problemLink`, then `titleUrl`. The fallback treats only null or absent as missing, so an empty-string `platformLink` stops the chain and the line is omitted. This is documented as "where the actual build logs live".
- **text-error-block**: When `errorText` is truthy, the text MUST append an empty line, then the line `error:`, then `errorText` verbatim, after the labeled lines.
- **text-commit-body**: When `commitBody` is truthy and differs from `commitSubject`, the text MUST append an empty line and then `commitBody` verbatim, after the error block.
- **text-omits-fields**: The text MUST NOT include `deployOutcome` or `problemLink` as their own lines. `problemLink` appears only through the `link` fallback.

### Contract-wide

- **pure-functions**: Both functions MUST be synchronous and side-effect free. Each MUST return a new value and MUST NOT mutate its argument.
- **no-throw**: Neither function throws for a well-formed argument. The host-extraction helper catches URL parse failures and returns its input, so a malformed `liveUrl` becomes the title unchanged.
- **concurrency**: The functions MAY be called from any context. They hold no state and cannot interleave.
- **module-private-set**: The non-deploy platform set MUST stay private to this logic. It is not exposed externally and nothing mutates it.

