
`overall.ts` (`packages/web/packages/status-web/src/lib/overall.ts`) is the status-web client's copy of the headline-status rollup. It exports the four-value `OverallStatus` type (`"operational"`, `"degraded"`, `"major_outage"`, `"unknown"`) and one pure function, `computeOverall`, which folds an array of per-service `HealthStatus` values (the three-value type from the sibling `health.ts`: `"healthy"`, `"degraded"`, `"down"`) into a single verdict.

The rule is: no statuses is `"unknown"`; every status `"down"` is `"major_outage"`; any status `"down"` or `"degraded"` short of all-down is `"degraded"`; otherwise `"operational"`.

Within status-web, `OverallStatus` is re-exported by `src/types.ts` and types the `overall` field of `StatusResponse`, the shape of the payload the status server returns. No status-web module calls `computeOverall` at runtime; the verdict a page shows arrives already computed in `StatusResponse.overall`. The status server owns the authoritative rollup in its own `monitor/overall.ts` (see [Status Server Monitor Overall](adtoolkit://cookbook/status/service/monitor/overall)), which carries the same `computeOverall` plus an extra `publicOverall` step that this client copy does not have.

