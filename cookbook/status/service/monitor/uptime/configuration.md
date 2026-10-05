
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| the check tally (the uptime-percentage calculation's and day-status classification's argument) | a four-field numeric record (`{ total, healthy, degraded, down }`) | none — required on every call | The per-endpoint check counts to score. Supplied fresh by the caller on each call; never defaulted, cached, or read from configuration by this component. |
| the service list (the overall-uptime mean's argument) | a list of records each carrying a nullable `uptimePercent` | none — required on every call | The list of already-computed per-service uptime percentages to average. Supplied fresh by the caller on each call; never defaulted, cached, or read from configuration by this component. |

This component reads no environment variable, consults no settings or feature-flag store, and receives no injected dependency of any kind — every value it needs arrives as a plain argument on that call.

