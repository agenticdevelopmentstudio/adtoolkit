
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |

**Separation of concerns.** The module owns only the selection rule; rendering, confirmation and deletion live in `StaleMonitorsBanner` and the API client.

**Unit test coverage.** `stale-monitors.test.ts` covers inclusion, the inclusive 7-day boundary, status and missing-onset exclusion, malformed timestamps, DNS neutrality, the status-code detail and sort order.

**Explicit error handling.** A malformed timestamp is handled by an explicit `Number.isFinite` guard rather than an exception or a silent pass-through.

**Data integrity.** A row is offered only on a parseable server-truth `downSince`, so no live monitor can be surfaced for deletion on data the function cannot judge.

**Graceful degradation.** Missing onset, unknown status or empty input yields fewer or no rows, never an error; the banner then renders nothing.

