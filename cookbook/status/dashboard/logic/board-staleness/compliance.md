
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | reliability |

**Separation of concerns.** The module holds only the rules and thresholds, with no I/O or React. The hook applies them.

**Unit test coverage.** `board-staleness.test.ts` covers every exported function at, below and above each threshold, plus the fail-closed and no-data paths.

**Explicit error handling.** Unparseable timestamps are handled by an explicit `Number.isFinite` guard, never by an exception.

**Graceful degradation.** An unknown probe cadence widens the window rather than narrowing it.

**Data integrity.** Garbage clocks fail closed, so a board is never claimed healthy on data the module cannot judge.

