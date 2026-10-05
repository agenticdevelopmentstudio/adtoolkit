
- **exported-surface**: The module MUST export the type `OverallStatus` and the named function `computeOverall`, and nothing else.
- **overall-status-values**: `OverallStatus` MUST be exactly the union of the four string literals `"operational"`, `"degraded"`, `"major_outage"` and `"unknown"`.
- **compute-overall-signature**: `computeOverall` MUST take one parameter `statuses` of type `HealthStatus[]` and return an `OverallStatus`.
- **health-status-input**: Each element of `statuses` MUST be a `HealthStatus` value (`"healthy"`, `"degraded"` or `"down"`); this is a caller precondition enforced by the type signature, and `"unknown"` is not a member of `HealthStatus`.
- **empty-is-unknown**: `computeOverall` MUST return `"unknown"` when `statuses` is an empty array.
- **all-down-is-major-outage**: `computeOverall` MUST return `"major_outage"` when `statuses` is non-empty and every element equals `"down"`.
- **any-down-or-degraded-is-degraded**: `computeOverall` MUST return `"degraded"` when `statuses` is non-empty, not every element equals `"down"`, and at least one element equals `"down"` or `"degraded"`.
- **all-healthy-is-operational**: `computeOverall` MUST return `"operational"` when `statuses` is non-empty and no element equals `"down"` or `"degraded"`.
- **check-order**: `computeOverall` MUST test its conditions in this order and return on the first match: empty array, then every element `"down"`, then some element `"down"` or `"degraded"`, then the fallback. An all-`"down"` array meets both the second and third conditions and MUST yield `"major_outage"`.
- **single-down-is-major-outage**: A one-element array `["down"]` MUST yield `"major_outage"`, because every element is `"down"`; a lone failing service is reported as a full outage.
- **order-independent**: The result MUST depend only on which values are present in `statuses` and whether all are `"down"`, not on element order or duplicate counts.
- **unrecognized-element-fallback**: An element outside `HealthStatus` that reaches the function at runtime (for example through an unchecked cast) MUST be treated as neither `"down"` nor `"degraded"`, so an array of only such values yields `"operational"`.
- **no-mutation**: `computeOverall` MUST NOT mutate `statuses`.
- **pure-synchronous**: `computeOverall` MUST be synchronous and MUST NOT perform I/O, logging, timers or any other side effect; its result depends only on its argument.
- **no-errors-raised**: `computeOverall` MUST NOT throw for any array argument; it has no error path, no cancellation and no timeout.
- **type-only-health-import**: The module MUST depend on `health.ts` only through a type-only import of `HealthStatus`, so it pulls in no runtime code.
- **no-runtime-caller-in-client**: Within status-web, `OverallStatus` MUST remain the type of `StatusResponse.overall`; the client MUST NOT recompute the headline from `services`, and displays the server's verdict unchanged.

