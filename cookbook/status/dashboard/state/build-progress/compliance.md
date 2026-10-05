
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [progress-indication](agenticdevelopercookbook://compliance/performance#progress-indication) | passed | performance |

The hook computes progress only; rendering lives in `BuildProgressBar` and filtering in `OverviewTab`, so concerns are separated. `use-build-progress.test.ts` covers the in-flight predicate, settle, server expiry, the absent client clock, the mixed cohort with the 2-second hold, and non-build rows; it does not cover hold cancellation by a new build, a row leaving the feed, or unmount cleanup, hence partial. The hook supplies determinate progress (completed/total, integer percent) for the build bar.

