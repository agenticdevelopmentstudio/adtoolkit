
### Exports and signature

- **poll-interval-constant**: The module MUST export `TELEMETRY_POLL_MS` equal to `60000` (60 seconds).
- **hook-signature**: The state MUST take no arguments and MUST return a snapshot object, never `undefined` or `null`.

### Data shape

- **snapshot-shape**: A snapshot MUST carry a `generatedAt` ISO timestamp string, a list of error entries (`errors`) and a list of analytics metric entries (`analytics`).
- **error-dto-shape**: Each error entry MUST carry `id`, `issueKey`, `project` and `title` (strings), `culprit`, `level`, `firstSeen`, `lastSeen` and `permalink` (string or `null`), and `count` and `userCount` (numbers).
- **analytics-dto-shape**: Each analytics metric entry MUST carry `metric` (for example `pageviews` or `visitors`), `window` (for example `24h` or `7d`), `scope` (`all` or a site slug), a numeric `value` and an ISO `capturedAt` string.
- **empty-snapshot**: Constructing an empty snapshot MUST return a new object `{ generatedAt: "", errors: [], analytics: [] }` on every call.

### Query configuration

- **query-key**: The state MUST read through a single shared read keyed `telemetry`, so every caller under one shared cache shares one cached snapshot and one poll.
- **query-fn**: The read MUST call the source's fetch operation with the injected API client (the context client, or the same-origin default whose base is `/api`).
- **poll-cadence**: The read MUST refetch every `TELEMETRY_POLL_MS` (60000 ms) while observed; the poll pauses by default while the document is hidden, since no override is set to keep it running in the background.
- **refetch-on-focus**: The read MUST refetch when the application regains focus, subject to the host cache's staleness setting, which the state does not set.
- **single-retry**: A failed fetch MUST be retried exactly once before the read enters its error state; this per-read setting overrides any retry default on the host cache. The delay before that retry is the platform's default retry delay, which the state does not set.

### Live source

This is the source variant currently wired in the composition root; an alternative backend is wired by changing one line there.

- **live-request**: The live source's read MUST issue one request to `/telemetry` with no request options (a `GET` to `<basePath>/telemetry`).
- **live-http-error**: A non-2xx response MUST make the live source's read reject with an error whose message is `telemetry <status>` (for example `telemetry 502`).
- **live-body-cast**: A 2xx response body MUST be parsed as JSON and returned as a snapshot object by cast, with no shape validation; a body that is not JSON rejects the read with the JSON parse error. The response shape is owned by the backend `/telemetry` route (see [Status Server Telemetry](adtoolkit://cookbook/status/service/telemetry)).

### Cache hydration

- **hydrate-after-mount**: The state MUST NOT read the cache during render; it MUST load from the cache exactly once per state instance, after the first mount.
- **first-render-empty**: On the first render of a state instance whose read has no data yet, the state MUST return the empty snapshot, so server-rendered output and the first client paint are identical.
- **cache-load-parse**: Loading from the cache MUST return the parsed value of the stored entry under the key `adh-telemetry-v1`, or `null` when the storage environment is unavailable or reading it throws.
- **parse-gate**: Parsing a stored value MUST return `null` when the raw value is `null` or empty, when it is not valid JSON, when it parses to `null`, when `generatedAt` is not a string, or when `errors` or `analytics` is not an array.
- **parse-projection**: When the gate passes, parsing MUST return a new object containing only `generatedAt`, `errors` and `analytics`, dropping any other top-level keys; array elements are not validated.

### Cache persistence

- **persist-on-data**: Whenever the read's data reference changes to a truthy value, each mounted state instance MUST save that value to the cache once.
- **cache-save-format**: Saving to the cache MUST write the snapshot as JSON under the key `adh-telemetry-v1`, replacing any previous value.
- **cache-save-best-effort**: Saving to the cache MUST do nothing when the storage environment is unavailable, and MUST swallow any exception the write throws; this is best-effort — the in-memory read result is the live truth.
- **no-save-on-failure**: A failed read MUST NOT write to or clear the cache; the last successful snapshot stays stored.

### Return precedence

- **live-wins**: When the read has data, the state MUST return that data, regardless of the cached snapshot.
- **cache-fallback**: When the read has no data and the cache load produced a snapshot, the state MUST return that cached snapshot.
- **empty-fallback**: When the read has no data and the cache load produced `null` (or has not run yet), the state MUST return the empty snapshot.
- **data-retained-on-error**: After at least one successful fetch in the shared cache, a later failed poll MUST leave the previous data in place (the platform keeps the last data on error), so the state keeps returning the last live snapshot rather than the cached one.
- **telemetry-failure-signal**: The state MUST return only the telemetry snapshot. It discards the read's error and loading flags, so a source that has never answered is indistinguishable from zero errors and zero traffic (the empty snapshot), and a cached or retained snapshot carries no staleness flag beyond its own generation time; consumer tests that mock the state with stale and offline fields describe fields the state never returns.

### Concurrency and side effects

- **shared-poll**: Multiple consumers using this state under one shared cache MUST share one in-flight fetch and one interval; additional callers MUST NOT add fetches beyond the cache's deduplication.
- **per-instance-cache-io**: Each mounted state instance MUST perform its own cache load on mount and its own cache save per new data value, so two mounted consumers read the cache twice and write the same snapshot twice.
- **side-effects**: The state's only side effects MUST be the source's network reads (one `GET /telemetry` per poll today) and the cache reads and writes under the key `adh-telemetry-v1`; it MUST NOT log, emit analytics, or mutate server state.
- **no-timeout-no-cancel**: The state MUST NOT impose its own request timeout or cancellation; the live source passes no cancellation signal to its request, so an in-flight request is not aborted by the platform's cancellation mechanism.
- **client-only**: Telemetry State MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

