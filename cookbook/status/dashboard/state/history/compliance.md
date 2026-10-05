
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | partial | reliability |

**Separation of Concerns**: The hook contains no presentation. The base path and transport live in `StatusApiClient`, the caching and state machine in React Query, and the rendering in `DetailPanel`.

**Unit Test Coverage**: There is no `use-history.test.ts` or `use-history.dom.test.tsx` beside the hook. It is exercised only indirectly, through components that render `DetailPanel`.

**Explicit Error Handling**: A non-ok status, a network rejection, and a JSON parse failure all reject the query function. Each one surfaces through the query's `error`, so none is swallowed. The server's error-body detail is not read.

**Timeout Handling**: The hook sets no timeout and passes no abort signal. A hung request leaves the query fetching, but it leaves no inconsistent state behind: the cache entry simply stays pending.

