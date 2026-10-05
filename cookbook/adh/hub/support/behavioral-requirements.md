
### Form/notice detail-pane factory

- **unavailable-message-constant**: A shared "not available" message
  constant MUST be the static string `"Not available in this version"`.
- **form-builds-editable-detail-pane**: Building a form detail (given an id,
  title, field specification, initial values, and an optional blocked
  reason) MUST return a detail-pane descriptor whose id and title are the
  given id and title arguments, and whose content-builder produces a form's
  mutable state from the given field specification and initial values, sets
  that state's blocked reason to the given value (default absent), and
  returns a form-hosting view constructed with that state and the shared
  markdown-editing injection point.
- **notice-is-single-readonly-field**: Building a read-only notice (given an
  id, title, and message) MUST build a field specification with exactly one
  section containing exactly one read-only field keyed `"notice"` and
  labeled with the given title.
- **notice-delegates-to-form**: Building a read-only notice MUST delegate to
  building an editable form with that one-field specification and the
  initial value `{"notice": message}`, supplying no blocked-reason argument,
  so it takes the form-builder's default absent value.

### Date parsing and formatting

- **formatters-built-once**: The date-parsing/formatting helper MUST build
  its four formatters (for fractional-second ISO-8601, whole-second
  ISO-8601, wire output, and human-readable display) as constants —
  constructed exactly once, never mutated afterward — per the source's own
  comment that building one per call "is expensive enough to show up when a
  rail formats a few hundred rows."
- **parse-tries-fractional-then-whole**: Parsing an ISO-8601 string MUST
  return absent when given an absent value or an empty string, and
  otherwise MUST attempt to parse it as ISO-8601 including fractional
  seconds first, falling back to parsing it as ISO-8601 without fractional
  seconds when the first attempt fails, and MUST return absent when both
  fail.
- **iso-formats-fixed-utc-string**: Formatting a date to its ISO-8601 wire
  representation MUST use a fixed calendar/locale/time-zone combination —
  the ISO-8601 calendar, the POSIX-invariant locale, and UTC (zero offset) —
  and the fixed pattern `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`, regardless of the
  caller's current locale or time zone.
- **display-uses-humane-formatter-or-fallback**: Formatting a date for
  display MUST return the caller-supplied fallback (default `"—"`) when
  parsing the given string fails, and otherwise MUST format the parsed date
  with a medium-date/short-time human-readable formatter, using that
  formatter's own default locale and time zone rather than the fixed
  UTC/invariant pair the wire formatter uses.
- **value-maps-to-form-value**: Mapping an ISO-8601 string to a form value
  MUST return a null form value when parsing the given string fails, and
  otherwise MUST return a date-typed form value wrapping the parsed date.

### Error normalization

- **wrap-passes-hub-error-through**: Normalizing an error MUST return its
  argument unchanged when that argument already is the shared named error
  type.
- **wrap-maps-other-errors-to-unexpected**: Normalizing an error MUST return
  an "unexpected" case carrying the argument's string description for any
  argument that is not already the shared named error type.
- **wrap-closure-rethrows-mapped-error**: The closure-taking form of error
  normalization MUST return the value produced by calling its body when the
  body does not throw, and MUST throw the normalized form of whatever error
  the body threw when it does.

### Blank-string normalization

- **non-blank-trims-and-nils-blank**: Trimming a string to a non-blank
  value MUST return absent when given an absent value or a string that is
  empty, or contains only whitespace and/or newline characters after
  trimming, and otherwise MUST return the trimmed string.

### JSON document value type

- **decode-precedence**: Decoding a JSON document value from a
  single-value container MUST try, in order, null, boolean, 64-bit integer,
  floating-point number, string, array-of-values, then object-of-values,
  taking the first that succeeds as the matching case, and MUST fail with a
  data-corrupted decoding error when none of the seven succeeds.
- **encode-passes-through-case-value**: Encoding a JSON document value MUST
  encode each case's associated value directly into a single-value
  container — an object as its dictionary, an array as its array, a string
  as its string, an integer as a 64-bit integer, a number as a
  floating-point value, a boolean as its bool, and null via the encoder's
  own null-encoding call — with no wrapper.
- **pretty-text-sorted-with-null-fallback**: Producing a pretty-printed text
  form of a JSON document value MUST encode it with pretty-printing and
  sorted keys enabled and return the resulting UTF-8 string, falling back to
  the literal string `"null"` when encoding or the UTF-8-to-text conversion
  fails.
- **parse-wraps-decoding-failure-as-validation**: Parsing a string as a
  JSON document value MUST decode it as UTF-8 JSON and, on failure, MUST
  throw a validation error with a message beginning `"Invalid JSON: "`
  followed by the underlying decoding error's debug description when the
  underlying error is a decoding error, or by that error's own localized
  description for any other thrown error.
- **integral-number-equals-decoded-int**: Equality between two JSON
  document values MUST treat an integer case and a number case as equal
  whenever the number is exactly representable as that same 64-bit integer
  value, in addition to the ordinary same-case equalities for object,
  array, string, integer-integer, number-number, boolean, and null; a
  number that is not exactly representable as a 64-bit integer, or whose
  exact integer value differs, MUST compare unequal to the integer case.
- **hash-matches-integral-number-equality**: Hashing a JSON document value
  MUST hash an integral number (one exactly representable as a 64-bit
  integer) identically to the integer case holding that same value, and
  MUST hash a non-integral number on a hash tag distinct from the
  integer/integral-number case, so that equality and hashing stay
  consistent with each other.
- **string-dictionary-requires-all-string-values**: Converting a JSON
  document value to a string-to-string dictionary MUST return absent when
  the value is not an object, and MUST return absent when any value inside
  that object is not a string; only when the value is an object and every
  value is a string MUST it return the dictionary of the unwrapped strings.

### Rail-path position lookups

- **id-bounds-checked**: Looking up the id at a position in a path array
  MUST return absent when the given index is not a valid index of the
  array, and otherwise MUST return that position's id.
- **last-returns-nil-for-empty-path**: Looking up the last item of a path
  array MUST return the array's last element, which is absent when the
  array is empty.

### Slug rules

- **make-projects-to-lowercase-hyphenated**: Projecting an input string to a
  slug MUST lowercase the input, keep only the ASCII letters `a`-`z` and
  digits `0`-`9`, and collapse every run of one or more disallowed
  characters between two kept characters into a single hyphen — implemented
  with a pending-hyphen flag that is flushed (appending one `"-"`) only
  immediately before the next allowed character is appended, and only when
  the output built so far is non-empty.
- **make-never-produces-leading-or-trailing-hyphen**: Projecting an input
  string to a slug MUST NOT emit a leading or trailing hyphen in its
  non-empty output: a pending hyphen is never flushed while the output
  built so far is still empty, and a pending hyphen still outstanding at the
  end of the input is never flushed at all.
- **make-returns-empty-for-no-valid-characters**: Projecting an input
  string to a slug MUST return the empty string `""` when the input
  contains no ASCII letter or digit.
- **is-valid-matches-pattern**: Validating a slug MUST return `true` if and
  only if the given string matches the shared slug pattern as a
  whole-string match: lowercase letters and digits only, with any interior
  hyphens single and never leading or trailing.
- **slug-length-unbounded**: The shared slug pattern and slug validation
  MUST NOT reject a slug for length alone; the given source defines no
  maximum length for either the pattern or the slug-projection output.

