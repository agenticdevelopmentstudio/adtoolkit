
- **activity-seconds**: `activitySeconds(sessionId, database)` MUST return the session's full history as ascending, unique epoch seconds, reading from the persistence layer only events with an id greater than the cached cursor (zero when uncached).
- **cursor-advance**: After a read, the cache MUST store the returned `lastId` as the new cursor together with the merged history.
- **merge-sorted-unique**: `merging(fresh, into: sorted)` MUST return an ascending, duplicate-free list containing every value of both inputs; `fresh` may be unordered and repeat.
- **merge-append-fast-path**: When every incoming value is later than the last held value, the merge MUST append rather than re-sort.
- **merge-empty-fresh**: An empty `fresh` MUST return `sorted` unchanged.
- **forget**: `forget(sessionId)` MUST drop the session's entry; it is called once the session has ended.
- **bounded**: The cache MUST hold at most `capacity` sessions (default 64) and evict the least recently used entry beyond that; an evicted session costs one full read if it returns.
- **read-error-propagates**: An error thrown by the persistence read MUST propagate to the caller and MUST leave the cached entry unchanged.
- **in-memory-only**: The cache MUST NOT persist anything to disk.

