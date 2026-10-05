
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [caching-strategy](agenticdevelopercookbook://compliance/performance#caching-strategy) | passed | performance |

The hook owns only the query definition and error-reason extraction; transport and base path belong to `StatusApiClient`, and rendering belongs to `Dashboard`. There is no test file for `use-status.ts`; `Dashboard.dom.test.tsx` replaces the hook with a mock, so neither the error-detail extraction nor the `status <code>` fallback is exercised, hence failed. Every failure path produces a thrown `Error` that reaches the UI, but a non-string `error` detail is coerced to an unhelpful message and a malformed success body is cast rather than validated, hence partial. Caching uses a single shared react-query key with refetch-on-focus and defers periodic refresh to the app-wide `useRefreshAll` interval.

