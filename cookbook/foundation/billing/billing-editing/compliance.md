
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | Best Practices |

separation-of-concerns passes: edits, repricing and titles are pure helpers; money arithmetic and rate parsing are the shared money utilities and the daemon owns the stamps. unit-test-coverage is partial: `BillingDTOEditingTests` covers `replacing`, clearing, `repriced` and the record titles and labels, but no test asserts the rate-text parsing range.

