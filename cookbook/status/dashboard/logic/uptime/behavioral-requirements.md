
### Data shapes

- **counts-shape**: Counts MUST carry exactly four numeric fields named `total`, `healthy`, `degraded` and `down`.
- **counts-not-validated**: This logic MUST NOT reject or correct a counts value whose `healthy` plus `degraded` plus `down` differs from `total`, or whose fields are negative, fractional or `NaN`; each function MUST compute directly on the values given.
- **service-input-shape**: The overall-uptime-percent function MUST accept any list of objects that carry an `uptimePercent` field (a number or null); other fields on the objects MUST be ignored.

### The uptime-percent function

- **uptime-null-when-no-checks**: The uptime-percent function MUST return `null` when `total` is less than or equal to 0.
- **uptime-degraded-counts-as-up**: The uptime-percent function MUST count both `healthy` and `degraded` checks as up; `down` MUST NOT enter the numerator.
- **uptime-denominator-total**: The uptime-percent function MUST divide by `total`, not by the sum of the three bucket counts.
- **uptime-two-decimal-rounding**: The uptime-percent function MUST return `(healthy + degraded) / total × 100` rounded to two decimal places by multiplying the ratio by 10000, rounding to the nearest integer with halves rounding toward positive infinity, then dividing by 100.
- **uptime-no-clamp**: The uptime-percent function MUST NOT clamp its result to the range 0–100; inconsistent counts (for example `healthy` greater than `total`) produce a value above 100.

### The day-status function

- **day-down-majority**: The day-status function MUST return `"down"` when `down` is greater than 0 and `down / total` is strictly greater than 0.5.
- **day-down-minority**: The day-status function MUST return `"degraded"` when `down` is greater than 0 and `down / total` is less than or equal to 0.5.
- **day-degraded**: The day-status function MUST return `"degraded"` when `down` is 0 or less and `degraded` is greater than 0.
- **day-healthy**: The day-status function MUST return `"healthy"` when neither `down` nor `degraded` is greater than 0, regardless of `total` and `healthy`.
- **day-down-checked-first**: The day-status function MUST evaluate the `down` count before the `degraded` count, so any day with a down check is never reported `"healthy"`.
- **day-zero-total-with-down**: The day-status function MUST return `"down"` when `total` is 0 and `down` is greater than 0, because the ratio evaluates to positive infinity; it performs no zero-total guard.

### The overall-uptime-percent function

- **overall-ignores-null**: The overall-uptime-percent function MUST drop every entry whose `uptimePercent` is null or absent before averaging.
- **overall-null-when-no-data**: The overall-uptime-percent function MUST return `null` when the input list is empty or every entry's `uptimePercent` is null.
- **overall-unweighted-mean**: The overall-uptime-percent function MUST return the arithmetic mean of the remaining values, each service weighted equally regardless of its check count or monitoring span.
- **overall-two-decimal-rounding**: The overall-uptime-percent function MUST round the mean to two decimal places by multiplying by 100, rounding to the nearest integer with halves rounding toward positive infinity, then dividing by 100.
- **overall-nan-propagates**: The overall-uptime-percent function MUST return `NaN` when any retained entry's `uptimePercent` is `NaN`, because `NaN` is a number and passes the null filter.

### Purity, ordering and side effects

- **pure-functions**: Every exported function MUST be pure: it MUST NOT mutate its argument, read or write any storage, perform network or file I/O, log, or depend on the clock.
- **synchronous**: Every exported function MUST return synchronously; this logic holds no state, so concurrent calls cannot interleave or affect each other.
- **no-errors-raised**: Every exported function MUST NOT throw for any input matching its type signature; "no data" is signalled by a `null` return, not an error.

