
The client-side store of the status dashboard's telemetry subsystem. It is the `localStorage` adapter of the `SnapshotCache` port (`telemetry/ports.ts`): it keeps the latest `TelemetrySnapshot` so the production-visibility band "paints instantly on reload and shows a last-known view while the source is briefly unreachable" (source comment in `stores/local-cache.ts`).

The module exports two things:

- `parseSnapshot(raw: string | null): TelemetrySnapshot | null` — a pure, browser-free parse that turns a stored string back into a snapshot, or `null` when anything about it is off.
- `localCache: SnapshotCache` — an object with `load()` and `save(snapshot)` that adds only the `window.localStorage` I/O around `parseSnapshot` and `JSON.stringify`.

The composition root `telemetry/client.ts` wires it as `export const cache: SnapshotCache = localCache;`, and the `useTelemetry` hook calls `cache.load()` once after mount and `cache.save(query.data)` whenever fresh data arrives (see [Status Web Hooks Use Telemetry](adtoolkit://cookbook/status/dashboard/state/telemetry)). Swapping the adapter is a one-line change at that root; nothing above the port moves.

Use it when a browser client needs a last-known copy of a small JSON snapshot that survives reload, where losing the copy is harmless because the live query is the source of truth.

