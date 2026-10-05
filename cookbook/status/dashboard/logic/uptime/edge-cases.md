
- **Empty input — no checks**: the uptime-percent function with `total` 0 MUST return `null`; the day-status function with all counts 0 MUST return `"healthy"`. The two functions therefore disagree on a no-data day: one says "no data", the other says "healthy". Callers that need a "no data" day state MUST check `total` themselves.
- **Empty input — no services**: the overall-uptime-percent function called with an empty list MUST return `null`, as MUST a list whose every entry's `uptimePercent` is `null`.
- **Missing field**: an entry whose `uptimePercent` is absent (outside the shape, but possible from untyped input) MUST be dropped like `null`, because the filter treats an absent value the same as `null`.
- **Boundary — exactly half down**: `down / total` equal to 0.5 MUST yield `"degraded"`, not `"down"`; the comparison is strictly greater than.
- **Boundary — negative total**: the uptime-percent function MUST return `null` for any `total` below 0.
- **Boundary — zero total with down checks**: the day-status function MUST return `"down"`, because a positive number divided by 0 is positive infinity.
- **Malformed input — inconsistent counts**: when the bucket counts do not sum to `total`, the uptime-percent function MUST still divide by `total` and MAY return values above 100 or below 0; no validation or clamping occurs (see counts-not-validated). The counts are produced by the status server, which owns their consistency.
- **Malformed input — NaN**: a `NaN` count makes the uptime-percent function return `NaN` (unless `total` itself is `NaN`, which fails the "total is less than or equal to 0" test and also yields `NaN`); a `NaN` `uptimePercent` in the service list makes the overall-uptime-percent function return `NaN`.
- **Floating-point rounding**: rounding goes through binary floating point, so a value whose exact decimal half lies just below the representable boundary MAY round down; ports MUST use IEEE 754 double arithmetic and the same multiply-round-divide sequence to match the reference output digit for digit.
- **Concurrent access**: not applicable — the functions are pure and hold no state, so any number of calls may run in any order with identical results.
- **Error states and offline**: not applicable — this logic performs no I/O and has no dependency that can fail or disconnect.
- **Cancellation and timeouts**: not applicable — every call completes synchronously in constant time for the uptime-percent and day-status functions, and linear time in the list length for the overall-uptime-percent function.

