
Not applicable: this file emits no user-facing string; `classify` returns only the internal `HealthStatus` literals (`"healthy"`, `"degraded"`, `"down"`), never displayed text — any operator-facing message built from a classification result (e.g. `probe.ts`'s `markerError`/`error` strings) is composed by callers external to this file.

