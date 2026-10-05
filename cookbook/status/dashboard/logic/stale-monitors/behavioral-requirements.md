
### Constant

- **stale-threshold-default**: `STALE_MONITOR_MS` MUST equal `7 * 24 * 60 * 60 * 1000`, which is 604 800 000 ms.
- **stale-threshold-view-only**: `STALE_MONITOR_MS` MUST only decide what is offered. Per its doc comment it is "Purely a VIEW threshold"; nothing the backend deletes depends on it.

### StaleMonitor shape

- **row-slug**: `StaleMonitor.slug` MUST be the input service's `slug`, which is the endpoint id and the delete target.
- **row-name-url**: `StaleMonitor.name` and `StaleMonitor.url` MUST be copied unchanged from the input service.
- **row-environment**: `StaleMonitor.environment` MUST be the input `environment` when it is truthy, and `null` when it is an empty string (the source uses `s.environment || null`).
- **row-detail-error**: `StaleMonitor.detail` MUST be the input `error` whenever `error` is neither `null` nor `undefined`, including an empty string (the source uses `??`).
- **row-detail-status-code**: When `error` is `null` or `undefined` and `statusCode` is not `null` or `undefined`, `StaleMonitor.detail` MUST be `"HTTP "` followed by the status code (for example `"HTTP 503"`).
- **row-detail-fallback**: When both `error` and `statusCode` are `null` or `undefined`, `StaleMonitor.detail` MUST be the literal `"down"`.
- **row-dns-ok**: `StaleMonitor.dnsOk` MUST be copied unchanged from the input `dnsOk`.
- **row-down-since**: `StaleMonitor.downSince` MUST be the input `downSince` string unchanged (an ISO timestamp that is server truth).
- **row-age**: `StaleMonitor.ageMs` MUST equal `nowMs - Date.parse(downSince)`.
- **row-projection**: The output row MUST carry only `slug`, `name`, `url`, `environment`, `detail`, `dnsOk`, `downSince` and `ageMs`. The other `LiveServiceDTO` fields (`group`, `platform`, `deployProject`, `responseTimeMs`, `lastCheckedAt`, `status`, `statusCode`, `error`) are deliberately dropped; the doc comment says no site or ownership data is needed because retiring is a single `deleteEndpoint(slug)` call.

### selectStaleMonitors

- **select-signature**: `selectStaleMonitors` MUST take `services: readonly LiveServiceDTO[]`, `nowMs: number` (epoch ms) and an optional `thresholdMs: number`, and MUST return a new `StaleMonitor[]`.
- **select-default-threshold**: When `thresholdMs` is omitted, the function MUST use `STALE_MONITOR_MS`.
- **select-down-only**: The function MUST skip every service whose `status` is not exactly `"down"` (so `"healthy"`, `"degraded"` and `"unknown"` are never selected).
- **select-requires-down-since**: The function MUST skip a `"down"` service whose `downSince` is falsy (`null` or an empty string), because an unknown onset cannot be judged.
- **select-non-finite-age**: The function MUST skip a service whose computed age is not finite (a malformed `downSince` that `Date.parse` returns `NaN` for), so a bad timestamp never surfaces a monitor as a retire candidate.
- **select-inclusive-threshold**: The function MUST include a service whose age is exactly `thresholdMs`; only an age strictly less than `thresholdMs` is excluded.
- **select-dns-neutral**: The function MUST select the same rows whatever each service's `dnsOk` value is. DNS neither triggers nor withholds the offer.
- **select-sort-order**: The returned array MUST be sorted by `ageMs` descending (longest-down first).
- **select-sort-ties**: Rows with equal `ageMs` MUST keep their input order, because `Array.prototype.sort` is stable.
- **select-empty-input**: An empty `services` array MUST return an empty array.
- **select-no-mutation**: The function MUST NOT mutate `services` or any service object; it builds a fresh output array.

### Purity and concurrency

- **pure-function**: `selectStaleMonitors` MUST be synchronous and MUST NOT perform I/O, log, read the clock or throw on any input of the declared types. Its result depends only on `(services, nowMs, thresholdMs)`, which the header states is so "the rule is unit-testable".
- **no-deletion**: The module MUST NOT delete, retire or otherwise act on any monitor. Retiring is the caller's `deleteEndpoint` call, and the backend owns the atomic removal of an emptied site.
- **single-threaded**: The module holds no state and runs on the single JavaScript thread, so concurrent calls cannot interleave and it needs no ordering rule.
- **caller-clock**: The caller MUST supply `nowMs`. The sole call site passes the client clock floored to the day (`Math.floor(nowMs / 86_400_000) * 86_400_000`), so ages are stable between 30-second ticks and the memoised result only recomputes once a day or when the services change.

