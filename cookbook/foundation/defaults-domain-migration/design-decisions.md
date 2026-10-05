
**Decision**: The legacy domain is never deleted after migration.
**Rationale**: A downgrade to the old build would otherwise lose every setting instead of just the ones changed since; the cost of keeping it is one small preferences file.
**Approved**: pending

**Decision**: The copy is all-or-nothing and gated on the new domain being empty, with no per-key merge.
**Rationale**: A merge would have to decide which side wins for each key; refusing to touch a non-empty domain guarantees a user who has already changed a setting under the new identifier is never overwritten.
**Approved**: pending

