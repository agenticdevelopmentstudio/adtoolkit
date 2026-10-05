
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |

`separation-of-concerns` passes because the type only represents and combines amounts; formatting, parsing, rounding to increments and per-currency bucketing live in the sibling money specs. `unit-test-coverage` passes because `AgenticToolkitCoreTests/MoneyTests.swift` covers the seconds-to-amount arithmetic including rounding, sign and zero guards, summing, subtraction, ordering and the same-currency test.

