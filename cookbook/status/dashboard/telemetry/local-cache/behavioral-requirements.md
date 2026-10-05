
### Data shape

- **snapshot-shape**: A `TelemetrySnapshot` MUST have exactly the fields `generatedAt: string` (ISO timestamp), `errors: ErrorDTO[]` and `analytics: AnalyticsMetricDTO[]`, as declared in `telemetry/types.ts`.
- **storage-key**: The adapter MUST store the snapshot under the single `localStorage` key `adh-telemetry-v1` (the module constant `KEY`).
- **single-slot**: The adapter MUST hold at most one snapshot; there is no history, list or per-source slot.

### Port contract

- **port-conformance**: `localCache` MUST implement the `SnapshotCache` interface: a synchronous `load(): TelemetrySnapshot | null` and a synchronous `save(snapshot: TelemetrySnapshot): void`.
- **synchronous-api**: `load` and `save` MUST NOT return a promise; both complete before returning to the caller.

### parseSnapshot

- **parse-null-empty**: `parseSnapshot` MUST return `null` when `raw` is `null` or the empty string, without attempting to parse.
- **parse-malformed-json**: `parseSnapshot` MUST return `null` when `raw` is not valid JSON; the `JSON.parse` exception MUST NOT propagate to the caller.
- **parse-json-null**: `parseSnapshot` MUST return `null` when `raw` parses to the JSON value `null`.
- **parse-generated-at-gate**: `parseSnapshot` MUST return `null` when the parsed value's `generatedAt` is not of type string.
- **parse-errors-gate**: `parseSnapshot` MUST return `null` when the parsed value's `errors` is not an array.
- **parse-analytics-gate**: `parseSnapshot` MUST return `null` when the parsed value's `analytics` is not an array.
- **parse-projection**: When all gates pass, `parseSnapshot` MUST return a new object containing only `generatedAt`, `errors` and `analytics`, dropping every other top-level key of the parsed value.
- **parse-shallow**: `parseSnapshot` MUST NOT validate the elements of `errors` or `analytics`; array contents are passed through as parsed.
- **parse-pure**: `parseSnapshot` MUST have no side effects and MUST NOT touch `window` or `localStorage`, so it runs outside a browser.

### load

- **load-no-window**: `localCache.load()` MUST return `null` when `window` is undefined (server render or non-browser runtime), without touching storage.
- **load-reads-key**: In a browser, `localCache.load()` MUST read `localStorage.getItem("adh-telemetry-v1")` and return `parseSnapshot` of that value.
- **load-missing-key**: `localCache.load()` MUST return `null` when the key is absent (`getItem` returns `null`).
- **load-storage-throws**: `localCache.load()` MUST return `null` when accessing `window.localStorage` or calling `getItem` throws (for example storage disabled by browser policy); the exception MUST NOT propagate.
- **load-no-cleanup**: `localCache.load()` MUST NOT remove or rewrite a stored value that fails the parse; the invalid value stays until the next `save` overwrites it.

### save

- **save-no-window**: `localCache.save(snapshot)` MUST do nothing when `window` is undefined.
- **save-format**: In a browser, `localCache.save(snapshot)` MUST write `JSON.stringify(snapshot)` to `localStorage` under the key `adh-telemetry-v1`.
- **save-overwrites**: Each `save` MUST replace the previously stored value in full; there is no merge with the old snapshot.
- **save-no-projection**: `save` MUST serialize the snapshot object as given, including any extra top-level keys the caller attached; only `parseSnapshot` on the read path drops them.
- **save-best-effort**: `localCache.save` MUST swallow any exception from accessing `localStorage` or from `setItem` (for example a quota-exceeded error), returning normally; the source comment declares this "best-effort — the in-memory query result is the live truth".
- **save-no-validation**: `save` MUST NOT validate the snapshot before writing; the `TelemetrySnapshot` parameter type is the caller's precondition.

### Durability

- **durability-reload**: A saved snapshot MUST survive a page reload and a browser restart for the same origin, for as long as the browser retains that origin's `localStorage`.
- **durability-loss-harmless**: Loss of the stored snapshot (cleared site data, private window, quota) MUST NOT be reported to the caller; `load` then returns `null` and the live query repopulates it.
- **no-expiry**: The adapter MUST NOT expire, age out or timestamp-check the stored snapshot; staleness is judged by consumers from `generatedAt`.

### Concurrency and side effects

- **single-threaded**: `load` and `save` MUST run synchronously on the browser's main JavaScript thread; calls from one page cannot interleave, and the last `save` to return is the stored value.
- **cross-tab-last-write**: Two tabs of the same origin share the one key; the adapter MUST NOT coordinate between them, so the value stored is whichever tab called `save` last.
- **only-side-effect**: The adapter's only side effect MUST be the read and write of the one `localStorage` key; it performs no network, logging, events or timers.

