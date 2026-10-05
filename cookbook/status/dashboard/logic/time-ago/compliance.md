
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [good-test-properties](agenticdevelopercookbook://compliance/best-practices#good-test-properties) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |

`unit-test-coverage` passes: `time-ago.test.ts` asserts every bucket and every bucket
boundary. `separation-of-concerns` passes: the file only formats, and it leaves the clock
to `useNow` and the surrounding wording to the components. `good-test-properties` passes:
the tests use a fixed `BASE` instant and no real clock, so they are fast, isolated and
repeatable. `explicit-error-handling` is partial: an unparseable timestamp is not checked
and instead comes out as the visible string `NaNd`, which is never thrown or reported to
the caller, and no test covers that path.

