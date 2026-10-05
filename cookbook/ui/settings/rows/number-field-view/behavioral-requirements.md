
- **builds-label-from-view-model-title**: Component MUST derive its label
  text from the view model's title.
- **right-aligns-field-text**: Component MUST right-align the field's text.
- **omits-input-formatter**: Component MUST NOT format or validate the
  field's text while the user is typing; parsing happens only on commit.
- **links-field-accessibility-title**: Component MUST associate the field's
  accessible name with its label, rather than a separate
  accessibility-label string.
- **themes-field-live**: Component MUST apply the code text role's font and
  the `.primaryText` color to the field, both immediately on construction
  and again every time the active theme changes.
- **fixes-field-width**: Component MUST constrain the field's width to the
  constant `fieldWidth` supplied at construction (default `72`).
- **aligns-label-when-width-fixed**: WHEN `labelWidth` is set, Component
  MUST right-align the label and pin its width to that constant.
- **lays-out-content-width-row-when-label-fixed**: WHEN `labelWidth` is
  set, Component MUST pin the row's top, leading, and bottom edges to the
  container and constrain the row's trailing edge to be no greater than the
  container's trailing edge.
- **lays-out-full-width-row-by-default**: WHEN `labelWidth` is not set,
  Component MUST pin the row to all four edges of the container instead of
  the content-width layout.
- **initializes-display-from-view-model**: At the end of initialization,
  Component MUST set the label's text to the view model's title and the
  field's text to the view model's value, in its field-string
  representation.
- **syncs-on-external-change**: Component's initializer MUST assign the
  view model's change-notification callback to one that re-sets the label
  and field text from the view model, and that callback MUST fire whenever
  the view model's change notification is invoked.
- **exposes-constituent-properties**: Component MUST expose the label, the
  field, `minimum`, and `maximum` as public, directly-accessible
  properties.
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.
- **commits-on-field-action**: Component MUST commit the field's text
  whenever the field's own change action fires.
- **commits-on-editing-end**: Component MUST commit the field's text
  whenever editing on it ends.
- **parses-committed-text-via-value-type**: Commit MUST parse the field's
  text via the number value contract's locale-aware parse operation for the
  field's declared value type.
- **reverts-on-unparseable-text**: WHEN commit cannot parse the field's
  text, it MUST leave the view model's value unchanged and MUST reset both
  the label and field text from the view model's current title/value.
- **clamps-to-bounds**: Unless **skips-clamp-on-contradictory-bounds**
  applies, commit MUST clamp a successfully parsed value up to `minimum`
  (if the value is lower) and then down to `maximum` (if the value is
  higher) before storing it.
- **skips-clamp-on-contradictory-bounds**: WHEN both `minimum` and
  `maximum` are set and `minimum` is greater than `maximum`, commit MUST
  store the parsed value unclamped.
- **redisplays-committed-text**: After computing the value to store, commit
  MUST set the field's text to that value's field-string representation
  whenever it differs from the field's current text.
- **skips-redundant-commits**: Commit MUST NOT write to the view model's
  value when the computed value equals its current value.
- **defines-number-parsing-contract**: The number value contract MUST
  declare a locale-aware parse operation that can fail, a field-string
  representation, and a flag indicating whether fractional values are
  allowed, and MUST itself support serialization, safe use across
  concurrent contexts, and ordering comparison.
- **provides-current-locale-parse**: The number value contract's default
  form MUST provide a parse operation that uses the active locale without
  requiring the caller to specify one.
- **requires-whole-string-locale-parse**: The shared locale-aware parse
  MUST use a decimal-style parser configured to allow or disallow
  fractional input per the type's float-allowance flag, and MUST reject the
  input unless the parser's consumed range covers the entire string.
- **trims-whitespace-before-parsing-int**: The integer conformance's parse
  operation MUST trim leading and trailing whitespace from the input before
  parsing.
- **parses-posix-integer-first**: The integer conformance's parse operation
  MUST accept a locale-invariant integer parse before attempting a
  locale-aware parse.
- **falls-back-to-locale-decimal-for-int**: WHEN the locale-invariant parse
  fails for an integer, the parse operation MUST attempt the locale-aware,
  whole-string decimal parse.
- **disallows-fractional-values-for-int**: The integer conformance's
  float-allowance flag MUST be false, so both the locale-invariant and
  locale-aware parse paths MUST reject any fractional spelling, including
  an integral-valued fractional spelling (e.g. `"1.0"`, `"1,0"`).
- **rejects-inexact-magnitude-for-int**: The locale-aware integer parse
  MUST reject a parsed number whose magnitude is not exactly representable
  as the integer type — via a finite, whole-number, exact-value check —
  rather than accepting a value a naive conversion would silently saturate.
- **writes-plain-integer-text**: The integer conformance's field-string
  representation MUST be a plain digit string, with no locale-specific
  grouping or decoration.
- **trims-whitespace-before-parsing-double**: The floating-point
  conformance's parse operation MUST trim leading and trailing whitespace
  from the input before parsing.
- **parses-posix-double-first**: The floating-point conformance's parse
  operation MUST accept a locale-invariant parse before attempting a
  locale-aware parse, but MUST reject a locale-invariant result that is not
  finite.
- **falls-back-to-locale-decimal-for-double**: WHEN the locale-invariant
  parse fails or is rejected for a floating-point value, the parse
  operation MUST attempt the locale-aware, whole-string decimal parse, and
  MUST reject a locale-aware result that is not finite.
- **allows-fractional-values-for-double**: The floating-point conformance's
  float-allowance flag MUST be true.
- **writes-whole-doubles-without-fraction**: The floating-point
  conformance's field-string representation MUST render a value equal to
  its own rounded value as an integer-looking string with no trailing
  fractional digits, and MUST fall back to the value's default decimal
  representation for any other value.

