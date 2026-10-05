
- **settings-and-keys**: The contract MUST expose the host's billing settings key set and read and write string settings by key.
- **transaction-atomic**: `transaction(body)` MUST run `body` as one write transaction: all of its writes land, or none do; an error thrown by `body` MUST roll everything back and propagate.
- **reset-derivation**: `resetBillingDerivationOfDerivedSessions` MUST forget every derived session's watermark so all derived time is re-split on the next pass, and return how many sessions were reset.
- **session-row**: A `BillingSessionRow` MUST carry session id, project root, branch, start instant, the last-activity value to stamp as the watermark once consumed, and whether the session is live.
- **segment-context**: A `BillingSegmentContext` MUST carry project id and repo id (both absent for Unassigned), project root, branch, zone, and a `tracked` flag; when `tracked` is false, time first derived under it MUST be flagged `untracked` and never rolled, even if tracking is later turned on.
- **overwrite-guard**: `upsertBillingEntry(dto, overwrite)` MUST always insert a new id, and for an existing row MUST apply the guard against the row as it is at write time: `any` overwrites any row, `unlocked` only an unlocked row, `rollupOwned` only an unlocked row with origin `auto`. It MUST return whether a row was written, false only when the guard refused.
- **stored-entry**: A `StoredBillingEntry` MUST pair the entry DTO with `descriptionEdited`, which decides whether the rollup may rewrite the description.
- **activity-cursor**: `billingActivitySeconds(sessionId, afterId)` MUST return the session's activity instants (epoch seconds) after the cursor and the cursor to resume from.
- **replace-derived**: `replaceDerivedSegments` MUST replace the session's derived segments with the given runs under the given context and history start, and return how many were written.
- **rollup-candidates**: `billingRollupCandidates(ids)` MUST return closed, unrolled segments of billing-enabled projects, narrowed to `ids` when given.
- **close-and-flag-booleans**: `closeBillingSegment`, `addBillingSegmentFlag`, `deleteEmptyBillingEntry` and `setBillingEntryDescription` MUST return whether a row changed.
- **explicit-arguments**: Every operation MUST be callable with every argument supplied; the contract defines no defaults.
- **overview-buckets**: `billingOverviewBuckets` MUST return, per currency, buckets keyed by status.

