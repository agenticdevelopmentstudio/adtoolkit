
**Decision**: Eviction is a linear scan for the stalest entry rather than a linked list.
**Rationale**: The type's documentation reasons that at capacities in the tens the scan is cheaper than the pointer-chasing structure that would avoid it; a larger capacity would need an ordered structure, which is a contained change to this one type.
**Approved**: pending

**Decision**: Recency is a counter, not a timestamp.
**Rationale**: An incrementing counter orders uses exactly and cannot tie, which a clock could, and needs no time source.
**Approved**: pending

