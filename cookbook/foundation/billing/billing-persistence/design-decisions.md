
**Decision**: The contract carries no schema; uniqueness and `NOT NULL` rules live in the host's tables.
**Rationale**: Rules such as the project-day-group unique index and a non-null entry project are named in comments but enforced by the host database; moving them into a shared migration would require a shared schema.
**Approved**: pending

