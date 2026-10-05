
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

separation-of-concerns passes: only claim and rate resolution live here; enabled-ness is the store's decision and the rate is shared with the rollup. unit-test-coverage passes: `BillingRateResolutionTests` covers branch precedence, rate inheritance, Unassigned, billing-off claims, zero rate, missing project and the any-branch step.

