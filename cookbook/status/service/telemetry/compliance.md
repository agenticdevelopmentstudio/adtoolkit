
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |

**Separation of Concerns**: The `collect()` abstraction decouples fetching (provider API calls) from persistence (storage strategies). Each of `Fetcher`, `Store`, and `collectTelemetry`'s orchestration concerns is isolated behind an interface. Concrete adapters (GlitchTip fetcher, SQLite store, PostHog fetcher) are wired only at the composition root (`server.ts`), allowing tests and deployments to swap implementations without changing the core logic.

**Unit Test Coverage**: No test in the status-server package imports `collect`, `collectTelemetry`, `buildErrorsFetcher`, `buildAnalyticsFetcher` or `emptySnapshot`. Adjacent tests cover the GlitchTip fetcher, the errors store, and the HTTP telemetry routes, but the ok:false no-persist rule, `complete` defaulting, the configuration guards, fail-soft handling and the GlitchTip observation are untested at this layer.

