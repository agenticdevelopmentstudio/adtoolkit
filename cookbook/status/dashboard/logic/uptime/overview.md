
This logic is the client's copy of the uptime arithmetic. It has no I/O, no state and no dependencies beyond a health status (see [Health Classification](adtoolkit://cookbook/status/dashboard/logic/health)). It exports:

- **counts**: a shape of four numbers: `total`, `healthy`, `degraded`, `down`.
- **the uptime-percent function** — takes counts and returns a number or null: the share of checks that were up (healthy or degraded), as a percentage rounded to two decimals, or null when there were no checks.
- **the day-status function** — takes counts and returns a health status: collapses a day's counts to one `"healthy"`, `"degraded"` or `"down"` verdict.
- **the overall-uptime-percent function** — takes a list of services and returns a number or null: the portfolio-wide uptime, the simple unweighted mean of each service's own uptime percent, rounded to two decimals, or null when no service has data.

At runtime only the overall-uptime-percent function is called: the overview tab view passes it the list of services from [the uptime state](adtoolkit://cookbook/status/dashboard/state/uptime), or an empty list while loading, and renders the result in the overview stats view. The per-day uptime-percent and status values arrive already computed from the status server, whose own counterpart (see [Status Server Monitor Uptime](adtoolkit://cookbook/status/service/monitor/uptime)) carries the same three functions and backs the `/uptime` read route. The two implementations differ only in comments and line wrapping.

Use this component whenever a port must reproduce the status page's uptime numbers exactly: the rounding and the "degraded counts as up" rule are what make the numbers match.

