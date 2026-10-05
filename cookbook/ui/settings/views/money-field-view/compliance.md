
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: parsing, formatting and storage are injected, so the row only lays out a text field and applies the parse result. Unit-test-coverage is partial: `MoneyFieldViewTests.swift` covers parsing, blanks and the stored amount with its placeholder; the revert after a refusal and a currency change are not tested.

