
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | failed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |

**Separation of concerns.** The module is one pure parsing function with no React, DOM or I/O. Presentation choices, such as empty-label fallbacks and lowercasing, stay with the calling components.

**Unit test coverage.** There is no `url.test.ts`. `row-detail.test.ts` reaches `hostOf` only indirectly through `rowDetail` titles, and no test asserts the fallback, empty-host or port behavior.

**Explicit error handling.** The parse error is caught on purpose and mapped to a documented fallback, so nothing throws. The catch is bare, though: the error is dropped without logging, and the return value cannot tell a caller whether parsing failed (host-of-failure-indistinguishable).

**Graceful degradation.** Unparseable input still produces a usable label (the original string) instead of an exception or a blank, so board rows render when a URL is malformed.

