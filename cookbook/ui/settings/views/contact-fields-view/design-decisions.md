
**Decision**: Row titles and the default header are hardcoded English.
**Rationale**: The view is used by one host today; closing the gap needs string keys.
**Approved**: pending

**Decision**: No field is validated.
**Rationale**: A half-typed phone number is normal and a client with no email is normal; validation is left to whoever consumes the record.
**Approved**: pending

**Decision**: Loading a different record while a field is being edited requires the caller to end editing first.
**Rationale**: The view cannot tell a reload of the same record from a different one; making it safe would need a record identity the type does not carry.
**Approved**: pending

