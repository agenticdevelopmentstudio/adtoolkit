
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | best-practices |
| [good-test-properties](agenticdevelopercookbook://compliance/best-practices#good-test-properties) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |

`uptime.ts` is pure arithmetic with no I/O, rendering or state, separated from the hook that fetches the data and the component that displays it, so separation-of-concerns passes. `uptime.test.ts` covers every exported function, including the null paths and each `dayStatus` branch, with small independent Vitest cases, so unit-test-coverage and good-test-properties pass. explicit-error-handling is partial: "no data" is signalled explicitly with `null`, but inconsistent or `NaN` counts pass through unvalidated and surface as out-of-range or `NaN` percentages rather than being rejected; the boundary cases (exactly half down, zero total with down checks, negative total) are not in the test suite.

