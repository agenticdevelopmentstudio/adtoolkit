
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | reliability |

**Separation of concerns.** The module owns only the vocabulary. Classification of deploy-backed kinds stays with the engine, and it re-exports rather than restating the engine's set.

**Unit test coverage.** No test file exercises `ENDPOINT_KINDS` or `isEndpointKind` in status-web. The re-exported `NON_DEPLOY_KINDS` is covered indirectly by the engine's `classify.test.ts`, which asserts `endpointNeedsWiring` for all six kinds.

**Explicit error handling.** The guard returns `false` for any non-member rather than throwing, and the result is typed as a predicate so callers must branch on it.

**Data integrity.** Within status-web the list, type and guard cannot drift apart. The status server restates the same list by hand with no parity test, and nothing checks that `NON_DEPLOY_KINDS` stays a subset of `ENDPOINT_KINDS`, so cross-package agreement rests on review.

