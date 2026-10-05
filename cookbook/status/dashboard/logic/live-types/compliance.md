
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |

The module holds only the wire contract, with transport, selection and rendering in other modules, so separation-of-concerns passes. Unit-test-coverage is partial: the fixture and the consumer tests (`use-live-snapshot.test.ts`, `stale-monitors.test.ts`) exercise the shapes, but no test pins these types to the server's copy. Data-integrity is partial for the same reason and because no runtime check rejects a mismatched payload. Graceful-degradation passes: the three newer fields are optional and each has a documented fallback for an older backend.

