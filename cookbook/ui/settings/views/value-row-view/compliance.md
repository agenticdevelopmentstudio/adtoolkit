
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

Separation-of-concerns is passed: the row only lays out two themed labels and holds no settings or storage logic. Unit-test-coverage is partial: `ValueRowViewTests.swift` covers the title and value and the accessibility label and selectability, but not the alignment or monospaced digits.

