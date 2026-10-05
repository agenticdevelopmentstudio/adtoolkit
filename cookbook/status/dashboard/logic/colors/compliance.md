
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |

**Separation of concerns.** The module holds only color data and two pure helpers, with no React, DOM or I/O; components apply the values and the theme package owns the token values.

**Unit test coverage.** There is no `colors.test.ts`, and no test asserts `envColor`, `envBadgeLabel` or the table contents; `row-model.test.ts` covers only `row-model`'s own tone colors.

**Explicit error handling.** `envColor` handles nullish and unknown input with an explicit fallback, and missing status keys return `undefined` for the caller to handle. The env lookups do not restrict themselves to own keys, so inherited object members leak through as non-string values (see env-object-prototype-keys), and `envBadgeLabel` throws on nullish input, which its type signature forbids.

