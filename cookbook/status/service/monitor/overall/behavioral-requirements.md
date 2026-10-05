
### Data Shape

- **overall-status-values**: An overall status MUST be exactly one of `"operational"`, `"degraded"`, `"major_outage"`, or `"unknown"`.
- **health-status-input**: The per-endpoint list given to both the base rollup and the public headline fold MUST be a list whose elements are health values as defined by the health-classification module (`"healthy"`, `"degraded"`, or `"down"`); `"unknown"` is not a member of that vocabulary and therefore MUST NOT appear as an element of the list.

### Base Rollup

- **empty-statuses-is-unknown**: The base rollup MUST return `"unknown"` when the per-endpoint list is empty, independent of any other condition.
- **all-down-is-major-outage**: The base rollup MUST return `"major_outage"` when the per-endpoint list is non-empty and every element equals `"down"`.
- **any-down-or-degraded-is-degraded**: The base rollup MUST return `"degraded"` when the per-endpoint list is non-empty, not every element equals `"down"`, and at least one element equals `"down"` or `"degraded"`.
- **all-healthy-is-operational**: The base rollup MUST return `"operational"` when the per-endpoint list is non-empty and no element equals `"down"` or `"degraded"` — that is, every element equals `"healthy"`.
- **compute-overall-check-order**: The base rollup MUST evaluate its four conditions in exactly this order, returning on the first match: (1) empty list; (2) every element `"down"`; (3) some element `"down"` or `"degraded"`; (4) otherwise. This order is observable at the all-down boundary: an all-`"down"` list satisfies both condition (2) and condition (3), and condition (2) MUST take precedence, yielding `"major_outage"` rather than `"degraded"`.

### Public Headline Fold

- **public-overall-base**: The public headline fold MUST compute its base verdict by running the base rollup over the per-endpoint list with no transformation of it.
- **non-endpoint-problem-degrades-operational**: The public headline fold MUST return `"degraded"` when the base verdict is `"operational"` AND the non-endpoint-problem flag is `true`.
- **non-endpoint-problem-never-escalates-past-degraded**: when the base verdict is `"operational"` and the non-endpoint-problem flag is `true`, the public headline fold MUST return `"degraded"`, and MUST NOT return `"major_outage"` on the basis of that flag alone.
- **non-endpoint-problem-never-lifts-unknown**: The public headline fold MUST return `"unknown"` unchanged when the base verdict is `"unknown"`, regardless of the non-endpoint-problem flag.
- **non-endpoint-problem-never-overrides-major-outage**: The public headline fold MUST return `"major_outage"` unchanged when the base verdict is `"major_outage"`, regardless of the non-endpoint-problem flag.
- **non-endpoint-problem-never-overrides-existing-degraded**: The public headline fold MUST return `"degraded"` unchanged when the base verdict is already `"degraded"`, regardless of the non-endpoint-problem flag.
- **no-problem-leaves-base-unchanged**: The public headline fold MUST return the base verdict unchanged, for any base verdict, when the non-endpoint-problem flag is `false`.

### Purity and Exports

- **pure-synchronous-functions**: The base rollup and the public headline fold MUST be synchronous, side-effect-free operations whose return value is computed only from their arguments; each MUST NOT perform I/O, logging, or mutation of the per-endpoint list.
- **exported-surface**: The overall-status vocabulary MUST be exported as a type, and the base rollup and the public headline fold MUST both be exported as named operations, from this module.

