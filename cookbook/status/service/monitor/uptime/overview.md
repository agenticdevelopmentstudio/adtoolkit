
This component is the status backend's pure uptime-arithmetic step: it turns
a day's (or a totals accumulation's) check tally — `total`, `healthy`,
`degraded`, `down` check counts for one endpoint — into a rounded uptime
percentage and a health status verdict, and separately turns a list of
per-service uptime percentages into one unweighted portfolio-wide
percentage. It performs no I/O of its own. It declares the check-tally shape
and three calculations: the uptime-percentage calculation, the day-status
classification, and the overall-uptime mean. The uptime-percentage
calculation and the day-status classification are consumed by the route
builder that produces the uptime response from stored daily counts; the
overall-uptime mean has no caller within this component's own host — see
Platform Notes for where each calculation is actually used and independently
duplicated.

