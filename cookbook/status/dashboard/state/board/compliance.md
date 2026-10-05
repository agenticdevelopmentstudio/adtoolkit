
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | partial | reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | reliability |

**Unit Test Coverage**: `use-board.dom.test.tsx` covers verbatim pass-through, the absence of `localStorage` writes, server-side removal propagating, live-frame refetch, the `stale`, `frozen` and `no-data` verdicts, the fresh-board pass-through, and agreement between `usePortfolioIndicator` and `GlobalPanel` on a stale or wedged board. `board-staleness.test.ts` covers the threshold functions. The initial-load, HTTP-error and retry paths are not asserted by the hook's own tests.

**Separation of Concerns**: Transport sits behind `StatusApiClient`, caching and polling behind React Query, the staleness rules and thresholds in `lib/board-staleness.ts`, and the clock in `useNow`; the hook only composes them and applies the verdict in one place.

**Explicit Error Handling**: HTTP failures throw a descriptive `Error`, parse failures propagate, and both surface through `error` and `reason: "unavailable"`; nothing is swallowed.

**Graceful Degradation**: When the stream is down the poll keeps the board current; when the API or the monitor fails the hook degrades to `board: null` with a cause instead of showing a retained verdict as current.

**Timeout Handling**: The hook sets no request timeout. A hung read does not leave a stale verdict on screen because the verdict is clock-driven, but the request itself is bounded only by the transport or a later cancel.

**Data Integrity**: The three clock fields are checked and fail closed, but the rest of the response body is cast to `Board` without runtime validation; shape conformance relies on the server contract and the compile-time drift guard in `board-types-parity.test.ts`.

