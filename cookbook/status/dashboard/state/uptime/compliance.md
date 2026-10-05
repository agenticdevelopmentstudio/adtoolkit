
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | partial | reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |

**Separation of Concerns**: The hook contains no presentation or computation. The base path and transport live in `StatusApiClient`, caching and the state machine in React Query, the uptime arithmetic in the backend and `lib/uptime.ts`, and the rendering in `Dashboard` and `OverviewTab`.

**Unit Test Coverage**: There is no `use-uptime.test.ts` or `use-uptime.dom.test.tsx` beside the hook, and the component tests that reach it mock it out, so the hook's fetch, key and error path are not exercised by any test.

**Explicit Error Handling**: A non-ok status, a network rejection, and a JSON parse failure all reject the query function and surface through the query's `error`, so none is swallowed. The server's error-body detail is not read.

**Timeout Handling**: The hook sets no timeout and passes no abort signal. A hung request leaves the query fetching indefinitely, though it leaves no inconsistent state behind.

**Graceful Degradation**: A failed refetch keeps the last successful data, and both callers fall back to an empty service list when no data exists, so the dashboard renders without uptime rather than failing.

