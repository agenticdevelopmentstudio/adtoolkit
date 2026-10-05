
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [health-observability](agenticdevelopercookbook://compliance/reliability#health-observability) | passed | reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | reliability |

**Separation of concerns.** The module holds only the classification rule and its thresholds. Fetching, timing, body capping and error-message wording live in the status-server probe.

**Unit test coverage.** `health.test.ts` covers the constants, every branch of `classify` (2xx, expected-status match, non-match, health body ok, not ok, non-JSON and unknown shape, marker present, missing and absent) and the latency threshold on both sides.

**Explicit error handling.** Partial. The `JSON.parse` failure is caught and deliberately discarded with a documented comment, and the caller always receives a verdict. There is no signal to tell "body was HTML" apart from "body was healthy".

**Health observability.** The module defines the three-valued verdict the dashboard shows for every endpoint, and it separates slow (degraded) from broken (down).

**Data integrity.** Partial. The numeric inputs are not validated, so a `NaN` latency classifies as healthy. The web copy is also kept identical to the server copy only by convention, with no parity test.

