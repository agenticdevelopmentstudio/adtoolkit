
- **Decision**: cap both the query and the fetch batch at `ENRICH_MAX_PER_CYCLE` (8) rather than fetching every currently-qualifying row each cycle.
  **Rationale**: per the module's own header comment, only a few rows are enriched per cycle by design, and because enrichment is idempotent (`error_text` is written once and the row is then permanently excluded from later scans by `listFailedWithoutError`'s own `isNull` predicate), any backlog drains over successive cycles "without a single cycle ever fetching enough to threaten the watchdog budget" — the external per-cycle time budget the surrounding `runCycle` is held to.
  **Approved**: pending
- **Decision**: rely on `listFailedWithoutError`'s newest-created-first ordering rather than oldest-first.
  **Rationale**: not explained in a comment on this file directly; recorded here as an observed, deliberate fact rather than an invented rationale. Under sustained load (more than 8 new unenriched failures within the 14-day window every cycle), this ordering means the oldest unenriched rows are the ones perpetually deprioritized behind fresher failures, and such a row can in principle age out of the `createdAfterMs` window before ever being selected — a genuine tension with the header comment's "any backlog drains" claim under that specific load pattern, traded off against the more actionable default of explaining the freshest failures first.
  **Approved**: pending
- **Decision**: honor the shared provider cooldown by filtering it INTO the candidate query's `platforms` argument, rather than querying unfiltered and catching a 429 per row.
  **Rationale**: stated directly in the source comment on the `polled` computation — a throttled provider's rows "wait for a later cycle rather than spending requests that extend the throttle," the same rule the sibling by-id reconcile healer applies to the identical shared `SharedArrayBuffer`-backed cooldown.
  **Approved**: pending
- **Decision**: return before ever calling `storage.deploy.listFailedWithoutError` when `polled` is empty, rather than issuing the query and discarding an empty-platforms result.
  **Rationale**: the inline comment on the check states the two possible causes plainly — "no token, or both cooling down" — either way nothing this cycle could fetch, so the DB round trip itself is skipped rather than spent and immediately thrown away.
  **Approved**: pending
- **Decision**: type `pollableByIdPlatforms`'s return as `ProviderName[]` (a fixed union of cooldown slot names) rather than `string[]`.
  **Rationale**: stated directly in that function's own doc comment (`deploy-platform/conn`) — a raw `platform` string (e.g. a stored row's `"cloudflare-pages"`) cast to `ProviderName` could otherwise smuggle a non-slot name into the cooldown module's `Atomics` index and throw a `RangeError` inside the monitor cycle; sourcing the candidate list from the fixed slot literals makes that cast impossible at this file's own call site.
  **Approved**: pending

