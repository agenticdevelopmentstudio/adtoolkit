
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | privacy-and-data |

The hook holds only selection state and persistence; the filtering of rows by environment lives in `OverviewTab`, so logic and presentation are separated. No test exercises `useEnvFilter` directly; the only coverage is `retired-storage.test.ts`, which asserts the `"adh-env-filter"` key survives the retired-storage purge, so hydration filtering and toggle persistence are untested. Both storage failures are caught and discarded without a log or signal. That is deliberate and commented in the source, but it falls short of the "MUST NOT be silently swallowed" bar, hence partial. When storage is unavailable the hook degrades to an in-memory filter that still works. Only environment names are stored, and nothing leaves the device.

