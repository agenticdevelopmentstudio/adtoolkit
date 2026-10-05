
**Decision**: Only the newest offered reload is kept; earlier held reloads are discarded rather than queued.
**Rationale**: A reload replaces the whole data set, so applying an older one before the newer would be wasted work and could briefly show stale rows; one slot is enough.
**Approved**: pending

**Decision**: The holder does not apply the reload itself.
**Rationale**: It returns the value and leaves the apply step to the table, so the type stays free of any UI knowledge and every table keeps its own reload mechanics.
**Approved**: pending

