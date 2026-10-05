
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | Best Practices |

separation-of-concerns passes: rolling and entry rules live here while storage is the persistence contract, and rate, rounding, money and the local-day rule are shared types. unit-test-coverage fails: no test in `AgenticToolkitCoreTests/Billing` calls `BillingRollup`; `BillingRoundingTests` and `BillingRateResolutionTests` cover only its collaborators.

