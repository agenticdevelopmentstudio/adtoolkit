
**Decision**: Formatters are cached by pattern, zone and locale.
**Rationale**: A table renders hundreds of rows per refresh, and a formatter costs tens of microseconds to build against well under one to reuse; the lock covers only the map.
**Approved**: pending

**Decision**: An ambiguous bare time returns both readings and leaves the choice to the caller.
**Rationale**: In a 12-hour locale a time typed over a shown one means whichever end of the day is nearest what the cell showed, which only the caller knows.
**Approved**: pending

