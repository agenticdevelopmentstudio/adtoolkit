
**Decision**: Timeouts and decode failures on reads collapse into one nil.
**Rationale**: The caller only needs "could not read"; distinguishing the causes would need an error type on every read.
**Approved**: pending

