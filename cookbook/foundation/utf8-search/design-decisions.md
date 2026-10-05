
**Decision**: Matching is byte-level, with no Unicode normalization.
**Rationale**: Normalization would reintroduce the per-character walk the type exists to avoid; callers that need canonically equivalent matching normalize before searching.
**Approved**: pending

