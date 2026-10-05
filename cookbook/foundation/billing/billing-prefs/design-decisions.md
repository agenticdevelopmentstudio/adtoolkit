
**Decision**: No test exercises `snapshot` or `apply` directly.
**Rationale**: Behavior is covered only indirectly through the store's passes; tests of clamping, fallbacks, the allow-list and the cutoff-change reset need an in-memory persistence stub.
**Approved**: pending

