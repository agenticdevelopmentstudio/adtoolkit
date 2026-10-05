
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [health-observability](agenticdevelopercookbook://compliance/reliability#health-observability) | partial | reliability |

**Separation of concerns.** The module holds only the rule and its thresholds, with no React, I/O or rendering; the banner and hook apply it.

**Unit test coverage.** `snapshot-staleness.test.ts` covers the floor and scaling of `snapshotStaleMs`, the missing-input, fresh, stale, very-stale, interval-scaling, NaN and negative-lag paths of `snapshotFreshness`.

**Explicit error handling.** Unparseable dates are handled by a deliberate negated comparison documented in the source, never by an exception.

**Graceful degradation.** An older backend with no `probeIntervalMs`, or a monitor with no probes, degrades to the floor window or to no banner rather than a false alarm.

**Health observability.** Partial: the rule surfaces data freshness to the user, but by design it fails open on unparseable or `NaN` inputs, so a malformed snapshot produces no staleness signal; cycle-completion health is left to the backend's `/health`.

