
- **Data collected**: Error-issue summaries (project, title, culprit, level, counts, first/last seen, permalink) and aggregate analytics KPIs; the error entry's `userCount` is a count, and the analytics are anonymous and aggregate. Error titles and culprits are application error text and can contain whatever the reporting app put in them.
- **Storage**: The latest snapshot is stored unencrypted in persistent browser storage under the key `adh-telemetry-v1`, and in memory in the shared cache.
- **Transmission**: The state sends one `GET /telemetry` through the injected API client per poll; it sends no telemetry data back out.
- **Retention**: The stored snapshot has no expiry; it is replaced on each successful poll and persists until overwritten or until the user clears site data.

