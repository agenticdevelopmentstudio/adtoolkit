
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |

**Unit Test Coverage**: `use-activity-history.dom.test.tsx` beside the hook covers disabled fetching, paging from the live tail's oldest row, the `before`/`beforeId` cursor pair, de-duplication, the MAX_AUTOPAGE_FETCHES budget, discarding history on disable, dropping a page that lands after a discard, error reporting without exhaustion, clearing the error on the next attempt, keeping the cursor after a failure, the shed-absorption guards (paged-only, OLD-end only, never `progress`, empty window as outage), and incoming-copy-wins replacement. The tests isolate the network by stubbing the global `fetch` that the default `useStatusApi()` client calls.

**Separation of Concerns**: The hook separates state management (useState for render-driven fields, useRef for stable-identity closures), side effects (shed absorption useEffect, cleanup on unmount), networking (fetch, timeout, abort), and data transformation (merge, sort). Each concern is addressable independently; a port can replace the networking layer without touching state logic.

