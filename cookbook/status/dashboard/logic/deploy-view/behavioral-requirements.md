
### Data shapes

- **platform-summary-shape**: the platform summary MUST have exactly the fields `platform` (a text value), `ready`, `building`, `failed` and `total` (each a count).
- **platform-summary-invariant**: For every platform summary returned, `ready + building + failed` MUST be less than or equal to `total`. Every deploy increments `total`, and at most one of the other three.
- **endpoint-like-shape**: the endpoint shape MUST have three optional, nullable fields — `platform`, `deployProject` and `environment` — each either a text value or absent. A structurally wider object (the host's endpoint roster entry) MUST be accepted.
- **platform-order-value**: the platform order list MUST equal `["vercel", "cloudflare-pages", "railway", "crunchy"]`, in that order.
- **platform-order-shared**: the platform order list MUST be exported, so that every platform-grouped surface (the deploy summary, and the auto-configure review view) orders sections from one list.

### Platform-summary operation

- **summarize-signature**: the platform-summary operation MUST take a list of deploy records, the current time (epoch milliseconds), and an optional probe-interval value (milliseconds), and MUST return a list of platform summaries.
- **summarize-group-key**: the platform-summary operation MUST group by each deploy's raw platform field, with no canonicalization. Deploys with `"cloudflare"` and `"cloudflare-pages"` MUST land in two separate summaries.
- **summarize-entry-creation**: The first deploy seen for a platform MUST create an entry with all four counts at 0 before that deploy is counted.
- **summarize-total**: Every deploy MUST increment its platform's `total` exactly once, whatever its status or staleness.
- **summarize-demotion**: A deploy for which the stale-in-flight test, given the deploy, the current time, and the probe interval, returns true MUST count in `total` only, and in none of `ready`, `building` or `failed`.
- **summarize-demotion-rule**: the stale-in-flight test MUST return false for any status other than the in-flight statuses (`building` or `queued`). For an in-flight status it MUST use the deploy's phase-confirmation time, falling back to its creation time when the phase-confirmation time is absent. It MUST return true when neither value is usable (fail closed), and otherwise return true only when the current time exceeds that time by strictly more than the greater of 600000 and five times the probe interval (treating a missing probe interval as zero).
- **summarize-ready**: A non-demoted deploy with status `"success"` MUST increment `ready`.
- **summarize-building**: A non-demoted deploy with status `"building"` or `"queued"` MUST increment `building`.
- **summarize-failed**: A deploy with status `"failed"` MUST increment `failed`.
- **summarize-total-only-statuses**: A deploy with status `"canceled"` or `"unknown"` MUST increment `total` only.
- **summarize-order-known**: The result MUST list the summaries for platforms in the platform order list first, in that order, including only the platforms present.
- **summarize-order-unknown**: Summaries for platforms not in the platform order list MUST follow the known ones, in the order each platform was first seen in the input.
- **summarize-empty**: the platform-summary operation on an empty list MUST return an empty list.

### Endpoint-deploys operation

- **endpoint-deploys-signature**: the endpoint-deploys operation MUST take a list of deploy records and an endpoint, and MUST return a new list of deploy records.
- **endpoint-key**: the endpoint-deploys operation MUST compute the endpoint key using the deploy-target-key operation on the endpoint's platform, project and environment fields.
- **endpoint-no-target**: When the endpoint key is absent (no platform, or no project, as for a health-only check), the endpoint-deploys operation MUST return an empty list.
- **endpoint-match**: A deploy MUST be included exactly when the deploy-target-key operation on its platform, project and environment fields equals the endpoint key.
- **target-key-format**: the deploy-target-key operation MUST return no key when the canonical platform is empty or the project is missing or empty. Otherwise it MUST return `"<canonPlatform>|<project>|<env>"`, where `<env>` is the lowercased environment (or `""` when the environment is absent) for `railway`, and `""` for every other platform.
- **platform-canon-rule**: the platform-canonicalization operation MUST map `"cloudflare-pages"` to `"cloudflare"`, an absent value to `""`, and every other value to itself.
- **endpoint-railway-env**: For a `railway` endpoint, a deploy of the same project in a different environment MUST NOT match. The match on environment MUST be case-insensitive.
- **endpoint-non-railway-env**: For a non-railway endpoint, the environment MUST NOT affect the match, because Vercel and Cloudflare projects are environment-specific.
- **endpoint-cloudflare-alias**: An endpoint configured with platform `"cloudflare"` MUST match deploys whose platform is `"cloudflare-pages"`, and the reverse.
- **endpoint-project-case**: The project name comparison MUST be case-sensitive. Only the environment is lowercased.
- **endpoint-sort**: The result MUST be sorted newest first by the deploy's creation timestamp.
- **endpoint-no-mutation**: the endpoint-deploys operation MUST NOT reorder or modify the caller's input list. It sorts a filtered copy.

### Latest-terminal-for-endpoint operation

- **latest-terminal-signature**: the latest-terminal-for-endpoint operation MUST take a list of deploy records and an endpoint, and MUST return a deploy record or no result.
- **latest-terminal-pick**: it MUST return the first deploy, in the endpoint-deploys operation's order (newest first), whose status is `"success"` or `"failed"`.
- **latest-terminal-skip**: it MUST skip deploys with status `"canceled"`, `"building"`, `"queued"` or `"unknown"`, even when they are newer.
- **latest-terminal-none**: it MUST return no result when no correlated deploy is terminal, and when the endpoint correlates to nothing.
- **latest-terminal-no-demotion**: it MUST NOT apply stale-in-flight demotion. It takes no clock argument.

### Failures-for-endpoint operation

- **failures-signature**: the failures-for-endpoint operation MUST take a list of deploy records and an endpoint, and MUST return a count.
- **failures-count**: it MUST return the count of correlated deploys whose status is exactly `"failed"`, across the whole input with no time window.
- **failures-zero**: it MUST return 0 when nothing correlates.

### Purity and concurrency

- **pure-functions**: Every exported operation MUST be synchronous and MUST NOT perform I/O, log, or mutate its arguments.
- **no-throw**: Every exported operation MUST NOT throw on input of the declared shapes. An unparseable date yields a non-comparable result and is handled by comparison, not by an exception.
- **single-threaded**: The module holds no state, so calls cannot interleave with each other, and no ordering rule between calls is needed.

