
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |

**Separation of concerns.** The module holds only aggregation and correlation rules, with no I/O or rendering. The key derivation is owned by the shared canon package, and the staleness rule by the row model.

**Unit test coverage.** The module's test suite covers every status bucket, stale demotion, platform ordering, the no-target, Vercel, Railway and Cloudflare correlation paths, newest-first sorting, terminal selection and failure counting.

**Explicit error handling.** Unparseable clocks in the demotion path are caught by a finite-value guard that fails closed, not by an exception.

**Data integrity.** A single shared key function keeps client and server correlation in agreement. Every deploy is counted in `total`, so demoted and canceled rows are never lost from the count.

**Graceful degradation.** A missing probe interval falls back to the 600 000 ms floor. An endpoint without a deploy target yields empty results rather than a guess.

