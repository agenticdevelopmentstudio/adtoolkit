
**Decision**: Out-of-range integers are clamped rather than treated as malformed.
**Rationale**: A hand-edited value that is too large still expresses an intent toward the high end; clamping keeps that intent while staying inside what the feature supports.
**Approved**: pending

**Decision**: Unrecognized boolean spellings fall back to the default instead of false.
**Rationale**: Each call site knows its own safe answer, so the caller supplies it; a global false would turn a garbled enable-flag into off even where on is the safe state.
**Approved**: pending

