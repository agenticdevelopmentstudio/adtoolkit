
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [resource-efficiency](agenticdevelopercookbook://compliance/performance#resource-efficiency) | passed | performance |

The hook does one thing — supply a stable, periodically refreshed timestamp — and leaves formatting and staleness logic to callers, so separation of concerns passes. There is no dedicated test file for `use-now.ts`; it is exercised only indirectly through `use-board.dom.test.tsx`, so unit test coverage is partial. Resource use passes: the timer is cleared on unmount and on interval change, and the coarse default limits re-renders, though every caller holds its own timer.

