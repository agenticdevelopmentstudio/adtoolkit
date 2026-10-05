
**Decision**: Duplicate-name checks are not atomic with the write.
**Rationale**: The check reads other records and then upserts outside one transaction; making it atomic needs the check inside `transaction`, and a unique index on the normalized name to back it.
**Approved**: pending

