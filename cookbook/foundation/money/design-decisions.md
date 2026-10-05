
**Decision**: Mixed-currency arithmetic fails rather than returning an error or a relabeled amount.
**Rationale**: Adding across currencies would silently relabel one amount as the other's currency, and ordering them is meaningless, so the type treats it as a programmer error caught in development rather than a value a caller must check.
**Approved**: pending

**Decision**: Seconds-to-amount rounds half-up, not banker's.
**Rationale**: Half-up is what a person checking the arithmetic by hand expects, and these amounts are not numerous enough for the statistical bias banker's rounding exists to remove to arise.
**Approved**: pending

**Decision**: The scale is always hundredths, whatever the currency's own minor unit.
**Rationale**: A shared scale means parsing multiplies by 100 and display divides by 100 for every currency, so the formatter and the type agree for currencies with no minor unit or three.
**Approved**: pending

