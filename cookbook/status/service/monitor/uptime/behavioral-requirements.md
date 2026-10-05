
### Data Shape

- **counts-shape**: The check tally MUST carry exactly four numeric fields — `total`, `healthy`, `degraded`, and `down` — each an aggregated count of checks for one endpoint over one accounting period (one day, or a summed range of days).
- **health-status-return**: The day-status classification MUST return one of exactly the three health status string literals — `"healthy"`, `"degraded"`, or `"down"` — and no other value.

### Uptime-Percentage Calculation

- **uptime-percent-formula**: When the total check count is greater than `0`, the uptime-percentage calculation MUST return the healthy-plus-degraded share of total checks, expressed as a percentage rounded to two decimal places (numerically, `round(((healthy + degraded) / total) * 10000) / 100`).
- **uptime-percent-degraded-counts-as-up**: The uptime-percentage calculation MUST count a `degraded` check together with a `healthy` check as up-time; only a `down` check reduces the returned percentage.
- **uptime-percent-no-data**: The uptime-percentage calculation MUST return `null`, without evaluating any ratio, whenever the total check count is less than or equal to `0`.

### Day-Status Classification

- **day-status-down-majority**: The day-status classification MUST return `"down"` when the down count is greater than `0` and the down-to-total ratio is strictly greater than `0.5`.
- **day-status-down-minority**: The day-status classification MUST return `"degraded"` when the down count is greater than `0` and the down-to-total ratio is `0.5` or less.
- **day-status-degraded-only**: The day-status classification MUST return `"degraded"` when the down count is `0` and the degraded count is greater than `0`.
- **day-status-healthy-default**: The day-status classification MUST return `"healthy"` when both the down and degraded counts are `0`, regardless of the value of the total or healthy count.
- **day-status-no-zero-total-guard**: The day-status classification MUST NOT special-case a total of zero or less the way the uptime-percentage calculation does; a day with zero checks of every kind MUST fall through to the same `"healthy"` result as a day that was actually checked and found fully healthy.

### Overall-Uptime Mean

- **overall-uptime-mean**: The overall-uptime mean MUST return the arithmetic mean, rounded to two decimal places, of the uptime-percentage field across every service entry whose uptime percentage is not `null`.
- **overall-uptime-excludes-null**: The overall-uptime mean MUST exclude any entry whose uptime-percentage field is `null` from both the sum and the divisor used to compute the mean; a service with no data MUST NOT be treated as a `0` and MUST NOT change the count of averaged entries.
- **overall-uptime-no-data**: The overall-uptime mean MUST return `null` when the service list is empty, or when every entry's uptime percentage is `null`.
- **overall-uptime-order-independent**: The overall-uptime mean's result MUST be independent of the order of the service list, since it computes an unweighted arithmetic mean over the entries that qualify.

### Purity and Concurrency

- **pure-computation**: The uptime-percentage calculation, the day-status classification, and the overall-uptime mean MUST perform no I/O and MUST mutate no argument, computing their return value solely from the arguments passed on that call.
- **concurrency-safety**: Because none of the three calculations read or write any shared state, they MUST be safely callable concurrently, in any order, from multiple callers (for example the same process handling several requests at once) without one call's result depending on another's.

