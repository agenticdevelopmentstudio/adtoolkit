
- **Null/empty input**: The view model is a required, non-optional
  constructor parameter, so a missing view model is not possible. Empty
  field text fails the parse for both conformances (a trimmed empty string
  fails both the locale-invariant and the locale-aware parse), so commit
  takes the revert path (**reverts-on-unparseable-text**) rather than
  storing zero.
- **Boundary values**: A typed value exactly equal to `minimum` or
  `maximum` commits unclamped (the clamp is a no-op at the boundary). A
  value one below `minimum` clamps up to `minimum`; one above `maximum`
  clamps down to `maximum`. When `minimum` and `maximum` are both set and
  `minimum > maximum`, clamping is skipped entirely and the raw typed value
  is stored (**skips-clamp-on-contradictory-bounds**) — a caller
  configuration error, not a range this component enforces.
- **Out-of-range magnitude (integer)**: A typed value whose magnitude
  exceeds what the integer type can hold exactly — per an exact-value check
  that catches the case a naive 64-bit conversion would otherwise silently
  saturate — is treated as unparseable and reverts rather than storing a
  clamped maximum/minimum value.
- **Non-finite values (floating-point)**: `"nan"`, `"inf"`, and `"-inf"`
  all parse syntactically as floating-point numbers, but the parse
  operation explicitly rejects a non-finite locale-invariant result and a
  non-finite locale-aware result, returning nothing rather than storing a
  NaN or infinite value that would make every bounds comparison in commit
  false.
- **Fractional and locale-formatted text (integer)**: A fractional string
  (`"1.5"`, or `"1,5"` in a comma-decimal locale) is rejected outright — the
  integer conformance's float-allowance flag is false, so the locale-aware
  parse refuses it, and the whole-string-consumed check refuses a partial
  parse like the leading `"1"` of `"1,5"`. An integral-valued fractional
  spelling (`"1.0"`) is refused for the same reason.
- **Whole-number round-trip stability (floating-point)**: A stored `20.0`
  renders as `"20"` (**writes-whole-doubles-without-fraction**) rather than
  `"20.0"`, so a field showing a value the caller never edited does not
  visibly rewrite it into a longer, decorated form.
- **Concurrent access**: The number value contract's parsing/formatting
  operations are synchronous, pure value-type code with no shared mutable
  state; only the component itself is confined to a single execution
  context (see **confines-to-ui-thread**), so all construction and
  mutation of the component is serialized to that context even though the
  parsing/formatting code it calls is not itself confined.
- **Error states**: Not applicable — every operation in this component
  (parsing, clamping, the committed write) is synchronous and
  non-throwing; the one internal parse step that can fail is caught locally
  and converted to a "no result" outcome, never propagated. No error
  reaches the caller.
- **Offline/disconnected state**: Not applicable — the component performs
  no networking; it only reads from and writes to an in-process view model.
- **Overwritten external observer**: The view model's change-notification
  callback is a single property. The initializer unconditionally replaces
  it with the component's own sync handler, replacing whatever handler (if
  any) was previously registered on that view model — the same
  closure-overwrite behavior the checkbox row and the captioned slider row
  document. The component MUST NOT be assumed to coexist with another
  change-notification observer already registered on the same view model
  instance.

