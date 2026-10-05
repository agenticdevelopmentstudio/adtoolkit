
- **Decision**: a currently-healthy probe (`stillServing`) vetoes the unclaimed-monitor deletion rule outright, even when the platform inventory condemns the same endpoint.
  **Rationale**: the source comment states it directly — a deploy project is keyed by NAME, so a rename or a team transfer at the provider reads exactly like a deletion; a URL that is still answering is a site worth watching regardless of what the inventory currently says, and a genuinely deleted project takes its own deployment down with it, so the healthy case is precisely the ambiguous one this veto exists to protect.
  **Approved**: pending
- **Decision**: split config deletion into two separate gates — a structural prune (step 0, `reconcileOrphanedEndpoints`) and a platform-inventory prune (step 8, `retireUnclaimedMonitors`) — rather than one combined check.
  **Rationale**: the source's own step-by-step comment states each answers "a different half of the same question": step 0 is about the configured group→site→endpoint chain no longer owning a row; step 8 is about no *provider* accounting for the row any more. Both are gated on evidence that survives a transient failure, but they read from entirely different sources of truth and would conflate two independent failure modes if merged.
  **Approved**: pending
- **Decision**: put the rate-limit cooldown check inside `guard` itself, the one wrapper every cycle poll crosses, rather than inside each fetcher.
  **Rationale**: source comment: doing it in each fetcher is "a convention a new provider's author has to remember (and where a typo'd name would silently disable it)." Centralizing it in `guard` makes the cooldown unconditional for every future provider poll added to this file.
  **Approved**: pending
- **Decision**: only run `pruneOlderThanDays(90)` when at least one deploy fetcher succeeded this cycle, rather than pruning unconditionally on a fixed schedule.
  **Rationale**: source comment: pruning unconditionally "avoid[s] deleting history when a temporary outage makes all fetchers return ok:false" — an all-providers-down cycle must not be indistinguishable, in its effect on stored history, from a genuinely stale set of rows.
  **Approved**: pending
- **Decision**: keep the bounded in-flight deploy reconcile (`reconcileVanishedDeploys`) and the ledger write (`reconcileBoardLedger`) running even on a `skipDeploys` (probe-only) tick, while skipping every other deploy-phase step.
  **Rationale**: source comment: only the deploy block terminalizes a finished build, so without this exemption the board kept asserting "building" for deploys the provider had already marked ready, for the full slow-cadence interval; the reconcile itself is "by-id, capped, and a no-op when nothing is in flight," so it costs one small query per tick and only does real work during a deploy burst — exactly when the board would otherwise go stale.
  **Approved**: pending

