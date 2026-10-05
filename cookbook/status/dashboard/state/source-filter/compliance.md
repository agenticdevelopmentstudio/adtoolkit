
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | privacy-and-data |

The hook holds only selection state. Row filtering and label rendering live in `ActivityPanel`, so state and presentation are kept apart. No test renders `useSourceFilter` directly. The only related assertion is in `row-model.test.ts`, which checks the default seed through `new Set(ISSUE_SOURCES)` rather than through the hook, so toggle behavior is untested. The hook has no failure path, so there is no error to swallow. It keeps only source identifiers in memory and sends nothing anywhere.

