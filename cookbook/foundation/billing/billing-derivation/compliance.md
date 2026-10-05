
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |

separation-of-concerns passes: derivation is pure; clocks, parsing and splitting are shared utilities and the caller supplies `now`. unit-test-coverage passes: `BillingDerivationTests` covers splitting, the cutoff boundary, sleep, open and closed final runs, lead-in, out-of-order, unparseable and malformed inputs, and fractional stamps.

