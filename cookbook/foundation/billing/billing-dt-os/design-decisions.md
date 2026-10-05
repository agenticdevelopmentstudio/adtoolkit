
**Decision**: Wire fields are plain strings (status, origin, rounding mode, granularity).
**Rationale**: Strings keep the wire stable and forward compatible; the cost is that typos compile, which the shared origin constants and the status enum offset where it matters.
**Approved**: pending

**Decision**: Refusal sentences are English constants.
**Rationale**: They travel verbatim to an alert; localizing them would need a code-per-refusal.
**Approved**: pending

