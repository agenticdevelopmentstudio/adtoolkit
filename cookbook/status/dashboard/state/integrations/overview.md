
Integrations is state in the status dashboard that loads the monitor's integration self-check snapshot: one entry per provider integration, saying whether it is configured, reachable and healthy. It wraps one cached read under the fixed key `["integrations"]`. It requests `/integrations` through the dashboard's status API client (see [status-web-api](adtoolkit://cookbook/status/dashboard/api)) and returns the query result typed as `IntegrationsResponse`. Integrations turns on refresh-on-returning-focus. It takes no arguments and is always enabled.

It has two callers. The Overview passes `data` to the self-check banner, so a failed or degraded self-check shows on the default wallboard. The dashboard passes `data` to the self-check computation for the header self-check pill. Both callers read only `data`.

