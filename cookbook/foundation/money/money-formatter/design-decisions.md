
**Decision**: Display always uses two fraction digits, whatever the currency's own minor unit.
**Rationale**: Letting the currency choose would round whole-unit currencies row by row while a total is formatted from the exact sum, so rows would not add up, and would give three-digit currencies a digit the stored value never had.
**Approved**: pending

**Decision**: Parsing decides the decimal separator from the text, not from the locale alone.
**Rationale**: A field that rejects an amount pasted from an email is a field people stop using, so the parser accepts either convention and refuses only the genuinely ambiguous case, because guessing there is how a rate ends up a thousand times too large.
**Approved**: pending

**Decision**: Unparseable text returns nothing rather than zero.
**Rationale**: A half-typed minus sign treated as zero would wipe the rate mid-keystroke; nothing lets the caller keep the previous value.
**Approved**: pending

