
`health.ts` (`packages/web/packages/status-web/src/lib/health.ts`) defines the status dashboard's three-valued endpoint verdict and the rule that produces it. It exports:

- `HealthStatus`, the string union `"healthy" | "degraded" | "down"`.
- `HEALTH_CHECK_TIMEOUT_MS` (10 000) and `DEGRADED_THRESHOLD_MS` (2 000).
- `ClassifyInput`, the facts one HTTP probe observed.
- `classify(input)`, a pure function that maps a `ClassifyInput` to a `HealthStatus`.

The file is a byte-identical copy of `packages/web/packages/status-server/src/monitor/health.ts` ([status-server health](adtoolkit://cookbook/status/service/monitor/health)). There the probe ([status-server probe](adtoolkit://cookbook/status/service/monitor/probe)) calls `classify` with every endpoint result. Inside status-web only the `HealthStatus` type is imported: by `src/types.ts` (which re-exports it and uses it for endpoint `status` fields), `src/lib/uptime.ts` (`dayStatus`) and `src/lib/overall.ts` (`computeOverall`). No status-web runtime code calls `classify` or reads either constant. They are exercised only by `health.test.ts`. The module has no state, no I/O and no side effects.

