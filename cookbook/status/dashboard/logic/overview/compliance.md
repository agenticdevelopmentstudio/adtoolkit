
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | reliability |

**Separation of concerns.** The module holds only presentation projections; derivation stays on the server and row construction in a separate module.

**Unit test coverage.** The module's own test suite covers the real-environment predicate and the window caption, and a parity test suite covers the problems-to-indicator operation and the wire-indicator translation map. The deploy-counts operation and the headline operation have no direct tests.

**Explicit error handling.** Nothing throws, but unparseable timestamps are not guarded: an unparseable time stamp is counted inside the window and an invalid bound yields a `"NaNh"` caption.

**Data integrity.** The indicator rule is pinned to the server by a parity test, but the real-environment predicate exists as two unpinned copies (web and server) despite a doc comment promising they cannot disagree.

