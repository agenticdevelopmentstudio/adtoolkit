
**Decision**: Duplicate repo rows for one root and branch resolve to the first in list order.
**Rationale**: The resolver reads whatever rows it is given and does not check uniqueness; the billing store's repo save refuses a second claim on the same root and branch and the host's unique index backstops it, so duplicates should not reach this layer, and if they do the first row wins.
**Approved**: pending

