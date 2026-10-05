
### GlitchTip Fetcher (glitchtip.ts)

- **unconfigured-no-op**: `glitchtipFetcher(env).fetch()` MUST resolve `{ ok: true, items: [] }` without issuing any network request when `env.GLITCHTIP_URL`, `env.GLITCHTIP_API_TOKEN`, or `env.GLITCHTIP_ORG` is missing.
- **issues-request-shape**: When all three are present, `fetch()` MUST issue exactly one `GET` request to `${GLITCHTIP_URL with trailing slashes stripped}/api/0/organizations/${GLITCHTIP_ORG}/issues/?query=is:unresolved&limit=${PAGE_LIMIT}` carrying header `Authorization: Bearer ${GLITCHTIP_API_TOKEN}`.
- **issues-request-timeout**: The request MUST be bounded by an `AbortController` whose signal aborts after `TIMEOUT_MS` (12,000ms), driven by `setTimeout`, and the timer MUST be cleared in a `finally` block regardless of outcome.
- **issues-no-retry**: `fetch()` MUST make exactly one request attempt per call; it MUST NOT retry a failed or timed-out attempt within the same call.
- **http-error-fails-poll**: When the response's `ok` is `false`, `fetch()` MUST resolve `{ ok: false, items: [] }` and MUST log a `console.warn` line naming the HTTP status, without throwing.
- **non-array-body-fails-poll**: When the parsed JSON body is not an `Array`, `fetch()` MUST resolve `{ ok: false, items: [] }` (never `ok: true`) and MUST log a `console.warn` line, regardless of whether the body looks like an error envelope, an HTML page, a `{results:[...]}` wrapper, or `null`.
- **thrown-fetch-fails-poll**: When the `fetch` call itself throws (a network failure or the timeout's abort), `fetch()` MUST catch it and resolve `{ ok: false, items: [] }`, logging a `console.warn` line that names the elapsed timeout when `err.name` is `"AbortError"` or `"TimeoutError"` (per `isTransient`), and the thrown error's message otherwise.
- **complete-flag-by-page-size**: On a successful array response, `fetch()` MUST set `FetchResult.complete` to `issues.length < PAGE_LIMIT` (100), so a page of exactly 100 issues is reported incomplete even if it happens to be GlitchTip's entire unresolved set.
- **issue-mapping-delegated**: On a successful array response, `fetch()` MUST set `FetchResult.items` to `mapIssues(issues)`, the module's pure, network-free mapping function.
- **issue-project-fallback**: `mapIssues` MUST resolve each item's `project` via `projectSlug`: the input `project`'s `slug`, else its `name`, else the literal string `"unknown"` — including when `project` itself is a string, `null`, or `undefined`.
- **issue-count-coercion**: `mapIssues` MUST coerce `count` to a `number`: pass a `number` through unchanged, `parseInt` a `string` (defaulting to `0` when parsing fails), and default `null`/`undefined` to `0`.
- **issue-timestamp-normalization**: `mapIssues` MUST normalize `firstSeen`/`lastSeen` via `normalizeIso`, returning `null` for a falsy input or a string that does not parse to a valid `Date`, and the `Date`'s own ISO string otherwise.
- **issue-field-defaults**: `mapIssues` MUST default `culprit`, `level`, and `permalink` to `null` and `userCount` to `0` when the corresponding input field is absent, and MUST copy `id`/`title` verbatim, setting `issueKey` to the same value as `id`.

### PostHog Fetcher (posthog.ts)

- **posthog-unconfigured-no-op**: `posthogFetcher(env).fetch()` MUST resolve `{ ok: true, items: [] }` without issuing any network request when `env.POSTHOG_HOST`, `env.POSTHOG_API_KEY`, or `env.POSTHOG_PROJECT_ID` is missing.
- **posthog-fixed-metric-set**: When all three are present, `fetch()` MUST query exactly the four fixed `METRICS` entries — `pageviews`/`24h` (1 day, non-distinct), `visitors`/`24h` (1 day, distinct), `pageviews`/`7d` (7 days, non-distinct), `visitors`/`7d` (7 days, distinct) — in that fixed order.
- **posthog-hogql-request-shape**: Each metric's query MUST `POST` to `${host with trailing slashes stripped}/api/projects/${projectId}/query/` with headers `Authorization: Bearer ${apiKey}` and `Content-Type: application/json`, body `{ query: { kind: "HogQLQuery", query } }`.
- **posthog-query-text**: The HogQL query text MUST select `count(DISTINCT person_id)` for a `distinct` metric and `count()` otherwise, `FROM events WHERE event = '$pageview' AND timestamp > now() - INTERVAL ${days} DAY`.
- **posthog-per-query-timeout**: Each of the four queries MUST carry its OWN `AbortController` timing out at `QUERY_TIMEOUT_MS` (10,000ms), independent of the other three queries' timeouts, with its timer cleared in a `finally` block.
- **posthog-sequential-execution**: The four metric queries MUST be issued sequentially, one at a time (never via `Promise.all` or other concurrent dispatch), so at most one HogQL request from this batch is outstanding at once.
- **posthog-short-circuit-on-first-failure**: When a query's `hogql` call resolves a non-null `error` (a non-`ok` HTTP response or a thrown request), `fetch()` MUST stop issuing any further metric queries in that batch, retaining only the items collected from queries that were answered before the failure.
- **posthog-single-warn-log**: When a batch stopped early on a failure, `fetch()` MUST log exactly one `console.warn` line naming the failure and the count of queries answered out of the fixed total (`${items.length}/${METRICS.length}`), never one line per failed query.
- **posthog-empty-result-fails**: `fetch()` MUST resolve `{ ok: false, items: [] }` when zero metrics were successfully queried in the batch, even when no query itself threw.
- **posthog-partial-result-succeeds**: `fetch()` MUST resolve `{ ok: true, items }` with whatever metrics succeeded before a later failure, whenever at least one metric was answered — a batch that answers some queries and fails on a later one MUST NOT discard the metrics it already has.
- **posthog-value-coercion**: `hogql` MUST resolve a `number` `results[0][0]` value unchanged and a `string` value via `Number(...)` (defaulting to `0` when the conversion is `NaN`), both with `error: null`.
- **posthog-captured-at-per-batch**: Every `AnalyticsMetricDTO` produced within one `fetch()` call MUST carry the identical `capturedAt` ISO string, captured once via `new Date().toISOString()` at the start of that call, never re-captured per metric.
- **posthog-scope-fixed**: Every `AnalyticsMetricDTO` this file emits MUST set `scope` to the literal string `"all"`.

### Shared Contract (ports.ts, referenced)

- **complete-flag-omission-vs-explicit**: Per `FetchResult.complete`'s documented default in `../ports` (unset defaults to `true`), `posthogFetcher` MUST leave `complete` unset on every result it returns, because its four-metric batch is never a partial page in the pagination sense; `glitchtipFetcher` MUST set `complete` explicitly on every successful result, per **complete-flag-by-page-size**, because its provider is cursor-paginated and a reconciling store depends on that signal being explicit rather than assumed.

