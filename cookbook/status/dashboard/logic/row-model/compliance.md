
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | reliability |
| [no-hardcoded-strings](agenticdevelopercookbook://compliance/internationalization#no-hardcoded-strings) | failed | internationalization |

The module separates row shaping from rendering (`StatusRow`) and from the server's judgments, so separation-of-concerns passes. Unit-test-coverage is partial: `row-model.test.ts` covers both builders, the adapter, search text, `commitUrlOf` and the demotion clock, but has no test for `rowToText` or `rowsToText`. Explicit-error-handling passes: nothing is caught or swallowed, and the one failure path (an unparseable deploy clock) is an explicit fail-closed branch. Graceful-degradation passes because the demotion clock degrades an unconfirmed in-flight deploy to "unknown" even when server healers are down. Data-integrity is partial because clipboard serialization promises aligned columns but does not escape tabs or newlines inside fields. No-hardcoded-strings fails because `STATE_LABEL` holds English status words inline.

