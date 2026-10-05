
### Data contract (types.ts)

- **error-dto-shape**: `ErrorDTO` MUST carry `id: string`, `issueKey: string`, `project: string`, `title: string`, `culprit: string | null`, `level: string | null`, `count: number`, `userCount: number`, `firstSeen: string | null`, `lastSeen: string | null` and `permalink: string | null`.
- **error-dto-id**: `ErrorDTO.id` is the stable key for rendering. It MUST hold the GlitchTip issue id when the data comes from the live path and the database row id when it comes from Turso.
- **error-dto-issue-key**: `ErrorDTO.issueKey` MUST be the GlitchTip issue id. It stays the same across polls and is the server store's upsert key.
- **error-dto-timestamps**: `ErrorDTO.firstSeen` and `ErrorDTO.lastSeen` MUST be ISO 8601 strings or `null`.
- **analytics-dto-shape**: `AnalyticsMetricDTO` MUST carry `metric: string`, `window: string`, `scope: string`, `value: number` and `capturedAt: string`.
- **analytics-dto-vocabulary**: The documented values are `metric` = `'pageviews' | 'visitors'`, `window` = `'24h' | '7d'`, and `scope` = `'all'` or a site slug. The type is plain `string`, so these values MUST be treated as documented conventions, not as enforced unions.
- **analytics-dto-aggregate**: An `AnalyticsMetricDTO` MUST describe one anonymous aggregate KPI sample (from PostHog), not per-user data.
- **snapshot-shape**: `TelemetrySnapshot` MUST carry `generatedAt: string` (ISO 8601), `errors: ErrorDTO[]` and `analytics: AnalyticsMetricDTO[]`. It is one self-contained read of everything the band shows.
- **empty-snapshot**: `emptySnapshot()` MUST return a new object `{ generatedAt: "", errors: [], analytics: [] }` on every call. An empty `generatedAt` marks "no data yet".
- **types-no-runtime-deps**: `types.ts` MUST NOT import any runtime module. Its only runtime export is `emptySnapshot`.
- **duplicated-definition**: The `types.ts` comment says the shape "is defined in exactly one place", meaning within status-web; `status-server/src/telemetry/types.ts` and `status-server/src/telemetry/ports.ts` are separate hand-maintained copies with no shared import, generation step or parity test (unlike `board-types-parity.test.ts` and `deploy-status-parity.test.ts`), and they already differ: the web `FetchResult` has no `complete` field, the web `Store.save` takes no `opts`, and the web `TelemetrySource.get` takes a `StatusApiClient` where the server's takes none. A port MUST follow the web copy for the client side.

### Ports (ports.ts)

- **fetch-result-shape**: `FetchResult<T>` MUST carry `ok: boolean` and `items: T[]`.
- **fetch-result-not-ok**: When `FetchResult.ok` is `false`, the provider poll failed. A caller MUST NOT treat the accompanying `items` (usually empty) as "no data", and MUST NOT overwrite or clear a store because of it, since that would wipe data during a temporary provider outage.
- **fetcher-port**: `Fetcher<T>` MUST expose `fetch(): Promise<FetchResult<T>>` and knows nothing about storage.
- **store-port-save**: `Store<T>.save(items: T[]): Promise<void>` MUST persist a freshly fetched set, using upsert or append depending on the stream.
- **store-port-load**: `Store<T>.load(): Promise<T[]>` MUST return the current persisted set.
- **store-port-server-only**: `Fetcher` and `Store` are server-side ports. No module in status-web implements them. They are declared here only to document the pipeline shape.
- **snapshot-cache-port**: `SnapshotCache` MUST expose a synchronous `load(): TelemetrySnapshot | null` and a synchronous `save(snapshot: TelemetrySnapshot): void`.
- **telemetry-source-port**: `TelemetrySource` MUST expose `get(api: StatusApiClient): Promise<TelemetrySnapshot>`. The caller supplies the API client, and every path is resolved through it.

### Composition root (client.ts)

- **cache-binding**: `client.ts` MUST export `cache` typed as `SnapshotCache` and bound to `localCache`.
- **source-binding**: `client.ts` MUST export `source` typed as `TelemetrySource` and bound to `SOURCES.live` (`liveSource`).
- **source-registry**: `client.ts` MUST keep a `SOURCES` map with both `live: liveSource` and `turso: tursoSource`, so either one can be selected by editing the single `source` line and nothing else.
- **static-selection**: Source selection MUST happen at build time, as a code edit. There is no runtime switch, environment variable or setting.

### Live source (sources/live.ts)

- **live-request**: `liveSource.get(api)` MUST issue exactly one `api.fetch("/telemetry")` per call.
- **live-http-error**: When the response is not `ok`, `liveSource.get` MUST reject with `Error("telemetry <status>")`, for example `telemetry 503`.
- **live-body**: When the response is `ok`, `liveSource.get` MUST resolve with the parsed JSON body cast to `TelemetrySnapshot`, including the server's `generatedAt`.
- **live-no-database**: The live path MUST NOT depend on Turso, so a database outage cannot affect the band.

### Turso source (sources/turso.ts)

- **turso-parallel-requests**: `tursoSource.get(api)` MUST issue `api.fetch("/errors")` and `api.fetch("/analytics")` in parallel.
- **turso-errors-http-error**: When the `/errors` response is not `ok`, `tursoSource.get` MUST reject with `Error("errors <status>")`. It checks `/errors` before `/analytics`.
- **turso-analytics-http-error**: When `/errors` is `ok` and `/analytics` is not, `tursoSource.get` MUST reject with `Error("analytics <status>")`.
- **turso-projection**: On success, `tursoSource.get` MUST resolve with `{ generatedAt, errors, analytics }`. `errors` is the `errors` field of the `/errors` body, `analytics` is the `metrics` field of the `/analytics` body, and `generatedAt` is the client's `new Date().toISOString()` at the moment of assembly, not a server timestamp.
- **source-response-trusted**: Both `liveSource` and `tursoSource` trust the status-server response contract and cast the response JSON to the DTO types without checking its shape, so a malformed body reaches the panels and is persisted by `cache.save` unchecked. `parseSnapshot` applies its shape gate only when a snapshot is read back from storage.

### localStorage cache (stores/local-cache.ts)

- **cache-key**: `localCache` MUST read and write the single localStorage key `adh-telemetry-v1`.
- **cache-save-format**: `localCache.save` MUST store `JSON.stringify(snapshot)` under that key and overwrite any earlier value.
- **cache-save-best-effort**: `localCache.save` MUST swallow any exception thrown by storage (quota, disabled storage) without rethrowing or logging. Per the source comment, "the in-memory query result is the live truth".
- **cache-ssr-guard**: Both `localCache.load` and `localCache.save` MUST do nothing when `window` is undefined (server render). In that case `load` returns `null`.
- **cache-load-parse**: `localCache.load` MUST return `parseSnapshot(localStorage.getItem(KEY))`, and MUST return `null` if reading storage throws.
- **parse-empty**: `parseSnapshot` MUST return `null` for `null` or empty-string input.
- **parse-malformed-json**: `parseSnapshot` MUST return `null` when `JSON.parse` throws.
- **parse-shape-gate**: `parseSnapshot` MUST return `null` unless the parsed value is truthy, `generatedAt` is a string, and both `errors` and `analytics` are arrays.
- **parse-projection**: On success, `parseSnapshot` MUST return a new object with only `generatedAt`, `errors` and `analytics`, and drop any other top-level keys. Array elements are passed through without per-field checks. This is a deliberate top-level-only gate.

### Concurrency and side effects

- **single-threaded**: All of this code runs on the browser's single JavaScript thread. `SnapshotCache` calls are synchronous and cannot interleave. Two overlapping `source.get` calls are independent fetches, and ordering their results is up to the caller (react-query in `useTelemetry`).
- **no-timeout-no-retry**: The sources MUST NOT apply their own timeout, cancellation or retry. Those come from the `StatusApiClient` fetch and from the calling hook (`retry: 1`, 60 s poll).
- **side-effects**: The only side effects are the HTTP GETs made by the sources and the single localStorage key written by `localCache.save`. Nothing in the subsystem logs.

