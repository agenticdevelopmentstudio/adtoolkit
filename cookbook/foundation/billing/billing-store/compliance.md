
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

separation-of-concerns passes: validation and derivation orchestration live here while storage is the persistence contract and rate resolution, rounding and derivation are their own types. unit-test-coverage fails: only `BillingRate` (via `BillingRateResolutionTests`) is tested directly; no test in `AgenticToolkitCoreTests/Billing` calls `BillingStore` save, delete or `deriveSegments`.

