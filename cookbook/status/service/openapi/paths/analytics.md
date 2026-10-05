
Not applicable: none of the 14 modules emits an analytics or telemetry event of its own; `telemetry.ts` documents endpoints that READ pre-aggregated `ErrorDTO`/`AnalyticsMetricDTO` rows computed elsewhere (`src/telemetry/*`) — it does not produce analytics data itself.

