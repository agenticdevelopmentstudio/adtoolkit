
**Decision**: The credential is a struct with public mutable fields rather than an immutable value.
**Rationale**: Rotating an account replaces the tokens and expiries in place, so callers update the fields they received from a refresh; a mutable value type keeps each copy independent. The cost is that nothing enforces that the four parts change together; that discipline stays with the custody layer.
**Approved**: pending

**Decision**: Token contents are not validated or redacted by the type.
**Rationale**: The type is a transport shape. Keeping secrets out of logs is the responsibility of whoever logs; closing this would mean adding a redacting description, which has not been needed because no caller prints the value.
**Approved**: pending

