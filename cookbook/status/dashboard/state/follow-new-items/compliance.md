
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [main-thread-freedom](agenticdevelopercookbook://compliance/performance#main-thread-freedom) | passed | performance |
| [resource-efficiency](agenticdevelopercookbook://compliance/performance#resource-efficiency) | passed | performance |

The hook owns one concern, scroll following, and splits the pure edge test (`atEdge`) from DOM work so it can be tested alone. `use-follow-new-items.test.ts` covers `atEdge` at and around the slack, resize re-pinning for both edges, the fallback path, and the anchored path including the capped-list rollover. The hook has no failure paths to handle: a missing container or a missing `ResizeObserver` is checked and skipped. The scroll listener is passive, the anchor search reads O(log n) rects without interleaved writes, and all listeners are removed on cleanup, so the hook does no work while the list is idle.

