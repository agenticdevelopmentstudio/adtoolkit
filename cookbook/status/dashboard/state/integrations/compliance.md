
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | partial | reliability |

**Separation of Concerns**: The hook has no presentation code. The base path and transport live in `StatusApiClient`, caching and the state machine in React Query, periodic refresh in `useRefreshAll`, and rendering in `SelfCheckBanner` and `computeSelfCheck`.

**Unit Test Coverage**: There is no `use-integrations.test.ts` or `use-integrations.dom.test.tsx` beside the hook. The `Dashboard` and `OverviewTab` DOM tests replace the module with a mock, so its own fetch and error paths never run in any test.

**Explicit Error Handling**: A non-ok status, a network rejection and a JSON parse failure all reject the query function and surface through the query's `error`, so none is swallowed. The server's error-body detail is not read, and neither caller renders `error`.

**Timeout Handling**: The hook sets no timeout and passes no abort signal. A hung request leaves the query fetching, but the cache entry just stays pending and nothing is left inconsistent.

