
The telemetry subsystem of the status dashboard's web client (`packages/web/packages/status-web/src/telemetry/`) defines what the "production-visibility band" shows (grouped error issues and headline analytics KPIs) and where the browser gets it from. It has three parts:

- `types.ts`: the data contract. These are pure DTO shapes (`ErrorDTO`, `AnalyticsMetricDTO`, `TelemetrySnapshot`) plus the `emptySnapshot()` factory. The file has "ZERO runtime dependencies (no db, no fetch, no react)".
- `ports.ts`: the ports. `FetchResult<T>`, `Fetcher<T>` and `Store<T>` describe the server-side poll-and-persist pipeline. `SnapshotCache` and `TelemetrySource` are the two client-side ports.
- `client.ts`: "THE client composition root". It exports one `cache: SnapshotCache` (wired to the localStorage adapter `localCache`) and one `source: TelemetrySource` (wired to `liveSource`). `tursoSource` is also wired, but inactive.

The [useTelemetry](adtoolkit://cookbook/status/dashboard/state/telemetry) hook uses only `cache` and `source`. Swapping the backend means changing one line in `client.ts`, and the hook, cache and panels stay the same. The server side that answers `/telemetry`, `/errors` and `/analytics` is covered by [Status Server Telemetry](adtoolkit://cookbook/status/service/telemetry). The `StatusApiClient` that every source reads through is covered by [Status Web API](adtoolkit://cookbook/status/dashboard/api).

