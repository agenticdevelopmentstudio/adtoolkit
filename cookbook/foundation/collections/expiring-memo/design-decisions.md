
**Decision**: The compute runs outside the lock, so concurrent misses for one key both compute.
**Rationale**: Holding the lock across an arbitrary compute would serialize unrelated keys and risk deadlock when a compute re-enters the memo; the type's documentation accepts duplicate work because callers that need single-flight already are.
**Approved**: pending

**Decision**: Eviction and sweeping scan the whole table.
**Rationale**: The capacity is intended to be small, where a linear scan beats maintaining an ordered structure; the cost would only matter at capacities far beyond the intended use.
**Approved**: pending

