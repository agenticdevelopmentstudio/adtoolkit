
**Decision**: Reading tries a hand-written fixed-width parser before the shared formatter-based parser.
**Rationale**: A formatter costs tens of microseconds to build and a daemon parsing every stamp of a long session spent most of its CPU doing so; the fast path handles nearly every stored instant and declines anything it cannot read exactly.
**Approved**: pending

**Decision**: A backwards or unparseable pair measures zero seconds.
**Rationale**: A negative duration would silently subtract from a total, so the safe failure is no time rather than negative time.
**Approved**: pending

**Decision**: Fractions truncate rather than round.
**Rationale**: An instant must never read later than it happened, and truncation keeps equal-second stamps equal.
**Approved**: pending

