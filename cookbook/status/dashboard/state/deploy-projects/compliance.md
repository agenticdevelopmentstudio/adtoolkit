
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [caching-strategy](agenticdevelopercookbook://compliance/performance#caching-strategy) | partial | performance |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | failed | reliability |

The module separates transport (the injected `StatusApiClient`), request shaping (the two fetch helpers) and caching (the React Query hook), which satisfies separation of concerns. No test exercises this module's own code; the only related test mocks `fetchUnconfigured` wholesale, so unit-test coverage fails. Every non-ok response becomes a thrown `Error` carrying the status and is surfaced to callers through promise rejection or query error state, so errors are explicit rather than swallowed. The caching strategy is deliberate (browser cache bypassed, 60 s client stale window, server 30 s cache bypassed on demand) but only partial, because an arm made while a fetch is in flight can be lost, leaving the next fetch cache-served contrary to the documented latch contract. No timeout is set on either request and React Query's abort signal is not forwarded, so a hung request stays pending indefinitely.

