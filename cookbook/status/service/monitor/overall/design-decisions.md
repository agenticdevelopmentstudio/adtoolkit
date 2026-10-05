
- **Decision**: evaluate `computeOverall`'s four conditions in the exact order empty → all-down → some-down-or-degraded → operational, rather than, for example, counting each status value.
  **Rationale**: not stated in an inline comment; recorded here as a fact of the code per this recipe's authoring rules. The order determines which branch an all-`"down"` array takes — conditions (2) and (3) both hold for that input, and (2) is checked first, yielding `"major_outage"` rather than `"degraded"` (compute-overall-check-order, status-server-monitor-overall-005).
  **Approved**: pending
- **Decision**: `publicOverall` only ever escalates a base verdict of `"operational"` to `"degraded"`; it never manufactures `"major_outage"` and never lifts `"unknown"`.
  **Rationale**: stated directly in the source's own doc comment on `publicOverall` — a non-endpoint problem "lifts an otherwise-operational verdict to degraded; it never manufactures a full outage (the sites are up) and never overrides an all-endpoints-down major_outage or an unknown (no-signal) rollup." The same comment states why the fold exists at all: a live site keeps serving HTTP 200 while its latest build/deploy fails or its platform API can't be polled, so those problems never show up in `statuses`, and without folding them in, "the landing reads All systems operational while deploys are red."
  **Approved**: pending
- **Decision**: `hasNonEndpointProblem` is a plain `boolean` the caller computes and passes in; `publicOverall` itself performs no lookup of what counts as a "non-endpoint problem."
  **Rationale**: not stated in an inline comment on this parameter itself; recorded here as a fact of the code, consistent with this file's purity (pure-synchronous-functions). The one caller in this codebase, `buildSnapshot` in `routes/reads.ts` (external to this file), derives the flag itself as any open board Problem whose `target` is not one of the monitored endpoint slugs.
  **Approved**: pending
- **Decision**: this recipe carries fewer Behavioral Requirements than its sibling `status-server-monitor-health` recipe.
  **Rationale**: `overall.ts` exports two short functions with a combined four early-return branches, versus `health.ts`'s single `classify` function with a five-step evaluation order, a JSON-parsing sub-branch, and several optional-field interactions; the difference in requirement count reflects a genuine difference in the number of distinct branches and interacting fields between the two files, not under-authoring of this recipe.
  **Approved**: pending

