
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |

**Separation of concerns.** The module owns only project identity and de-duplication. It knows nothing about environments, domains, React state or the network; the provider, review modal, picker and bulk-ignore surfaces import it instead of formatting keys themselves.

**Unit test coverage.** No test file in `status-web` exercises `projectKeyOf` or `uniqueByProject`, so first-seen ordering and key format are unverified by tests.

**Explicit error handling.** Both functions are total over their typed inputs and have no failure path to handle; nothing is caught or swallowed.

