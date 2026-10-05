
**Decision**: No floating-point number is used anywhere in the formatter or the parser.
**Rationale**: The billing path must stay exact: a Double would let a rounding error change an invoice, so fractions of an hour become seconds by integer arithmetic with half-up rounding.
**Approved**: pending

**Decision**: Seconds below a minute round down to `0m` in the reading form.
**Rationale**: The rounding rules already discarded sub-minute precision, and showing seconds would imply precision the billed figure does not have.
**Approved**: pending

