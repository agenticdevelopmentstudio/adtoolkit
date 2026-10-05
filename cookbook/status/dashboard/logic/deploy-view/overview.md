
This module is the status dashboard's view-side logic over raw deploy records. It has no state, no I/O and no side effects. It exports:

- a platform summary shape: a per-platform count record (platform, ready, building, failed, total).
- the platform order list: the shared stable ordering of known platforms, `["vercel", "cloudflare-pages", "railway", "crunchy"]`.
- the platform-summary operation: buckets deploys by status per platform. It demotes a stale in-flight deploy to "total only", using the same rule as the activity list and the deploy list. The build-pipeline pane and the KPI building pill call it.
- the endpoint shape: the deploy-target fields of a monitored endpoint (platform, deployProject, environment).
- the endpoint-deploys, latest-terminal-for-endpoint and failures-for-endpoint operations: correlate an endpoint to its deploys by the EXPLICIT (platform, project) wired on the endpoint in config, with "No host guessing." The detail panel and the status matrix call them.
- the deploy-target-key and platform-canonicalization operations: re-exported unchanged from a shared canon module. The source comment says they are "Re-exported (never restated) so the two sides can't key the same deploy differently" — the backend keys deploys with the same function.

The stale-in-flight test is a helper shared with the row model. The [Board Staleness](adtoolkit://cookbook/status/dashboard/logic/board-staleness) recipe shares its fail-closed clock rule.

