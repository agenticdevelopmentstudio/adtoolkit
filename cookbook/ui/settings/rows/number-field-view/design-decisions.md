
- **Decision**: Attach no live input formatter to the field, and parse only
  on commit (AppKit/UIKit source: no `NSFormatter`).
  **Rationale**: Per the source's own comment, a formatter with a minimum
  would reject valid intermediate text on the way to a valid number (e.g.
  typing "-" before "-5", or the "1" of "12" against a minimum of 10);
  parsing happens only on commit instead.
  **Approved**: pending
- **Decision**: Parse locale-invariant-first, falling back to a
  locale-aware parse only when the locale-invariant parse fails (or, for
  the floating-point conformance, produces a non-finite result).
  **Rationale**: Per the source's own comment on the number value contract,
  the field's own writer (its field-string representation) is
  locale-invariant; a locale-first parse risks misreading the
  locale-invariant text a sync just wrote as a locale-formatted number
  instead. The source itself notes this ordering is unobservable and
  deliberately untested for the integer conformance (its field-string
  representation emits no separators, so neither parse branch can see a
  string the other reads differently), while the floating-point
  conformance's ordering is pinned by a dedicated test, because its
  locale-invariant writer can emit a decimal point a locale-aware parse
  could misread.
  **Approved**: pending
- **Decision**: Skip clamping entirely when `minimum` and `maximum` are
  both set and `minimum > maximum`, rather than clamping to one of them.
  **Rationale**: Per the source's own comment, "a contradictory pair comes
  from a caller's own mistake, and the field's job then is to stay usable,
  not to enforce an empty range" — whichever bound clamping would apply
  first is an arbitrary artifact of the code's line order, so the source
  instead leaves the field unbounded in that case.
  **Approved**: pending
- **Decision**: Revert silently to the last committed value on unparseable
  text, rather than storing a coerced or default value.
  **Rationale**: Per the source's own comment, "text that is not a number of
  this type is not a zero; it is a typo," and a silently-stored zero (or a
  rounded fraction) would be a value the user never typed.
  **Approved**: pending
- **Decision**: Reject a parsed integer whose magnitude a naive 64-bit
  conversion would otherwise silently clamp, via an exact-value check
  (AppKit/UIKit source: `Int.settingsExactInt(from:)`), rather than
  accepting the clamped result.
  **Rationale**: Per the source's own comment, a naive 64-bit conversion
  saturates rather than failing on overflow, and converting to a
  double-precision float rounds up to a value indistinguishable from a true
  edge-of-range input, so only an exact (arbitrary-precision) comparison
  can tell a genuinely-typed maximum value apart from an overflow that
  would otherwise be silently stored as that maximum.
  **Approved**: pending
- **Decision**: Render a whole floating-point value without a trailing
  fraction (`20.0` → `"20"`) via a whole-number check, rather than always
  using the type's default decimal string form.
  **Rationale**: Per the source's own comment, the default decimal string
  form of `20.0` is `"20.0"`, and a field that turns the `20` a caller wrote
  into `20.0` the moment it is shown has edited a setting nobody touched.
  **Approved**: pending
- **Decision**: The component performs no contrast check of its own: the label and field text colors (the theme's primary-text role) resolve from the active theme at runtime, so whether a given theme's resolved pair reaches the 4.5:1 text threshold is not established by this component.
  **Rationale**: Contrast is a property of the theme's resolved color pairs, which live outside this component; closing the gap would take a theme-level audit (or an enforced minimum in the theme layer) of those roles against the backgrounds a settings row sits on, which no source or test does today.
  **Approved**: pending

