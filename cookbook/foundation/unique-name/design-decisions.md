
**Decision**: The next-name search compares exactly while the collision check folds case and whitespace.
**Rationale**: Generating a name from a snapshot only needs to avoid byte-equal duplicates, whereas refusing a rename must stop names that merely read alike in a list.
**Approved**: pending

