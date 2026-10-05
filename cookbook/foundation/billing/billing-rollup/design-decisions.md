
**Decision**: A repository assignment and its promotion are two separate calls rather than one transaction.
**Rationale**: If promotion fails after assignment, segments are assigned but not yet rolled; the next scheduled pass rolls them, so it self-heals. Making it atomic would wrap both in one transaction.
**Approved**: pending

