
- **Empty cache**: With no entries in the shared cache, `refreshAll` MUST still trigger a refetch. That call refetches nothing and resolves.
- **Only the live entry cached**: `refreshAll` MUST refetch nothing. Live Snapshot's own cache entry keeps its own cadence, set by Live Snapshot itself.
- **Empty cache key**: For an entry with an empty key, there is no first element to compare, so that entry MUST NOT be excluded as live. It is refetched if it is not disabled.
- **Non-string first key element**: The comparison is exact, so a first element that is not the string `"live"` (for example a number or another kind of value) MUST NOT be excluded.
- **Interval of 0, negative, or not a number**: Passed to the timer unchanged. The environment treats these as a zero delay, clamped to its own minimum timer interval, so Refresh All MUST then fire refreshes continuously. The only caller passes 60,000 ms; the value otherwise is a caller precondition.
- **Very large interval**: A value large enough can overflow a platform's timer-delay representation and fire almost immediately. Refresh All does not guard against this, and MUST pass the value through unchanged.
- **Tick during an in-flight fetch**: The shared cache cancels the running fetch and restarts it, by its own default behavior. Refresh All MUST NOT add its own deduplication.
- **Refetch failure / unreachable server / offline**: Each failing entry records its error in its own cache state, and Refresh All MUST NOT surface, retry or log it. Retries follow the host cache context's defaults. While offline, the shared cache's own network policy may pause fetches. That behavior belongs to the shared cache.
- **Background tab**: The timer keeps running, subject to the environment's own throttling. Refresh All MUST NOT skip or delay ticks itself.
- **Stopping use mid-refetch**: Refetches already started keep running and still update the cache. Stopping use of Refresh All only stops future ticks.
- **Cancellation and timeout**: Refresh All has no cancellation or timeout of its own. Timeouts, if any, belong to each entry's own read function and its transport.
- **Shared cache context swapped**: A new context changes `refreshAll`'s identity, so Refresh All restarts the timer against the new context. The old context gets no more ticks from this use.
- **Missing cache context**: Using Refresh All where no shared cache context is available MUST fail immediately.

