
- **constructor-contract**: The memo MUST be constructed with a time-to-live and a capacity, and MUST reject a capacity of zero or less as a programmer error.
- **serves-fresh-entry**: A lookup for a key MUST return the stored value without computing when the entry was stored strictly less than the time-to-live before the lookup time.
- **expires-at-ttl**: An entry that is exactly the time-to-live old, or older, MUST be recomputed and stored with the lookup time as its stored time.
- **clock-backwards-expires**: An entry stored later than the lookup time (a clock that went backwards) MUST be treated as expired and recomputed.
- **lookup-time-injectable**: The lookup time MUST be an optional parameter defaulting to the current time, so freshness is testable without waiting.
- **failed-compute-caches-nothing**: When the compute closure fails, the failure MUST propagate to the caller unchanged and no entry MUST be stored or changed.
- **compute-outside-lock**: The compute closure MUST run outside the memo's lock; two callers that miss the same key at the same time MAY both compute, and the last to finish stores its value.
- **sweep-on-store**: Storing a computed value MUST first discard every entry that is no longer fresh at the lookup time.
- **capacity-evicts-oldest**: After sweeping, when the key is not already held and the number of entries has reached the capacity, storing MUST drop the entry with the oldest stored time before inserting the new one.
- **count-includes-unswept**: The reported count MUST be the number of entries currently held, including entries that are stale but not yet swept.
- **remove-all**: The memo MUST offer a way to forget every entry.

