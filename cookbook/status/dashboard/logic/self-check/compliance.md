
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [good-test-properties](agenticdevelopercookbook://compliance/best-practices#good-test-properties) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |

The module passes separation-of-concerns: it holds only the derivation from report to view, with rendering in `SelfCheckBanner.tsx` and fetching in the integrations hook. `self-check.test.ts` covers the loading null, the all-ok null, warn and error missing env with dedupe, the cron exclusion, the correlated collapse and a lone warning, so unit-test-coverage passes; the empty-array and ok-state-with-missing-env paths are untested but follow directly from the filter. The tests are small, deterministic and independent, each built from the `check` and `report` fixture factories, so good-test-properties passes. explicit-error-handling passes because the function is total over its typed input and has no error path to swallow; a malformed report is a typed caller precondition.

