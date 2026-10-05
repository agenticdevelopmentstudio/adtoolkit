
### Data Shapes

- **platform-summary-shape**: A `PlatformSummary` value MUST carry exactly five fields — `platform: string`, `ready: number`, `building: number`, `failed: number`, `total: number` — with no other field.
- **endpoint-like-shape**: An `EndpointLike` value MUST carry `platform`, `deployProject`, and `environment`, each typed `string | null` and each OPTIONAL (a caller MAY omit any of the three entirely, not only pass `null`).
- **canon-reexport**: This module MUST re-export the `platformCanon` and `deployTargetKey` functions it imports from `@agentic-toolkit/deploy-platform/canon` unchanged, so a caller importing either name from `./overview` gets the identical function, and identical results, as a caller importing it directly from the `canon` package.

### Platform Summarization

- **platform-grouping**: `summarizeByPlatform` MUST group input `DeploymentDTO` rows by the raw, uncanonicalized `d.platform` string; it MUST NOT pass `d.platform` through `platformCanon` before grouping, so a `"cloudflare-pages"` row and a `"cloudflare"` row (were both ever present) produce two separate `PlatformSummary` entries rather than one merged entry — unlike this same file's endpoint-correlation functions, which canonicalize the platform through `deployTargetKey` before comparing.
- **status-bucket-mapping**: For each `DeploymentDTO` grouped into a platform's entry, `summarizeByPlatform` MUST increment `total` by one, and MUST additionally increment exactly one of `ready` (when `status === "success"`), `building` (when `status === "building"` or `status === "queued"`), or `failed` (when `status === "failed"`).
- **status-bucket-omission**: `summarizeByPlatform` MUST leave `ready`, `building`, and `failed` all unchanged — incrementing only `total` — for a `DeploymentDTO` whose `status` is `"canceled"` or `"unknown"`; the source's own doc comment names only `canceled` for this treatment, but the code's `if`/`else if` chain matches none of `"canceled"` or `"unknown"` against any literal, so both fall through identically to total-only counting.
- **platform-summary-ordering**: `summarizeByPlatform` MUST order its returned array by placing every platform present in the fixed list `["vercel", "cloudflare-pages", "railway", "crunchy"]` first, in that exact sequence (skipping any of the four not present in the input), followed by every other platform encountered, in the order each was first encountered while iterating the input array.

### Endpoint Correlation

- **deploy-target-key-precondition**: `deploysForEndpoint` MUST return an empty array, without inspecting the `deploys` argument, when `deployTargetKey(ep.platform, ep.deployProject, ep.environment)` returns `null` — which `deployTargetKey` does whenever `ep.platform` canonicalizes to an empty string or `ep.deployProject` is falsy, i.e. an endpoint with no platform or no project wired (a health-only check) correlates to nothing.
- **deploy-endpoint-correlation**: When the endpoint's key is non-`null`, `deploysForEndpoint` MUST return every `DeploymentDTO` in `deploys` whose own `deployTargetKey(d.platform, d.projectName, d.environment)` equals that same key — matching the endpoint's `deployProject` field against the deploy row's differently-named `projectName` field — and MUST exclude every row whose key differs, including one that shares the platform or project but not both (or, for `"railway"`, not the environment as well, per `deployTargetKey`'s railway-specific environment matching).
- **deploy-endpoint-sort**: `deploysForEndpoint` MUST return its matches sorted by `createdAt` descending (newest first), computed as `+new Date(b.createdAt) - +new Date(a.createdAt)`.
- **latest-terminal-selection**: `latestTerminalForEndpoint` MUST return the first element of `deploysForEndpoint(deploys, ep)` — i.e. the newest by `createdAt` — whose `status` is `"success"` or `"failed"`, skipping every element before it, and MUST return `null` when no element in that list has either status; the source's own doc comment names `canceled`, `building`, and `queued` as the statuses skipped, but the code's `find` predicate accepts only `"success"` or `"failed"`, so a `"unknown"`-status row is skipped identically even though the comment does not name it.
- **failure-count**: `failuresForEndpoint` MUST return the count of elements in `deploysForEndpoint(deploys, ep)` whose `status` is `"failed"`.

### Ordering and Concurrency

- **module-purity**: Every function this file exports MUST be a pure function of the arguments passed to it: none reads or writes any variable outside its own call, the file holds no top-level mutable state (the one module-level constant, the platform-order list, is never reassigned or mutated by any exported function), and none performs an `await`, a callback registration, or any I/O. Because JavaScript executes one module instance's code on a single thread and nothing here yields to the event loop mid-computation, two calls into any of this file's functions from the same thread MUST NOT interleave in a way that corrupts either call's result — a structural fact of the runtime and this file's statelessness, not a lock this file implements.

