
- **Decision**: `glitchtipFetcher` makes exactly one bounded attempt per poll and never retries a failed or timed-out request.
  **Rationale**: the source comment states this directly — the issues query already fans out over source-maps and grouping and can occasionally stall, so a retry on a stalled provider would double that cycle's wait; under sustained degradation, stacked retries blew the scheduler's cycle budget and triggered container restarts.
  **Approved**: pending
- **Decision**: a GlitchTip response of exactly `PAGE_LIMIT` (100) issues is always treated as truncated (`complete: false`), even though 100 could coincidentally be the provider's true total.
  **Rationale**: the source comment explains the asymmetry directly — a reconciling store reads "absent from this poll" as "resolved upstream," which is sound for a whole answer and catastrophic for a truncated page (an issue past the page edge would be resolved on one poll and reopened on the next, flapping the board forever); erring toward "may not have seen everything" costs a delayed resolve, while erring the other way costs a false all-clear during a live incident.
  **Approved**: pending
- **Decision**: the four PostHog HogQL queries are issued sequentially, never concurrently.
  **Rationale**: stated directly in the source comment — the HogQL query API returns HTTP 503 under concurrent load from this same client, so sequential dispatch is a gentleness constraint on the provider, not merely a stylistic choice.
  **Approved**: pending
- **Decision**: a PostHog batch that fails partway through keeps the metrics it already answered rather than discarding the whole batch; only an all-failed batch resolves `ok: false`.
  **Rationale**: the source comment states this directly — persisting whatever succeeded means a total outage is the only case that returns `ok: false`, so a partial provider degradation never overwrites already-good trend data (in the external `Store`) with an empty set.
  **Approved**: pending

**Decision**: A malformed but ok PostHog result shape is not signaled as a failure.
**Rationale**: It stands today because only transport and HTTP errors count as failures. Closing it needs a decision on how strictly to validate the response shape, and a test for each malformed shape.
**Approved**: pending

