
- **Null and empty input**: Parsing an absent value and parsing an empty
  string MUST both return absent (MUST, `parse-tries-fractional-then-whole`).
  Trimming an absent value and trimming an empty string to non-blank MUST
  both return absent (MUST, `non-blank-trims-and-nils-blank`). Projecting an
  empty string to a slug MUST return `""` (MUST,
  `make-returns-empty-for-no-valid-characters`). Looking up the last item of
  an empty path array MUST return absent (MUST,
  `last-returns-nil-for-empty-path`). Parsing an empty string as a JSON
  document value (empty string, not valid JSON) MUST throw a validation
  error via `parse-wraps-decoding-failure-as-validation`, since an empty
  string decodes as none of the seven cases.
- **Boundary values**: Looking up an id by position MUST return absent
  exactly at and beyond the array's length (and for any negative index),
  never trap (MUST, `id-bounds-checked`). The shared slug pattern and slug
  validation impose no maximum length, so a 300-character
  all-lowercase-letter string MUST still validate (MUST,
  `slug-length-unbounded`). The integer case of a JSON document value MUST
  round-trip a value as large as 2^53 + 1 exactly, the smallest integer a
  floating-point number cannot represent exactly, because 64-bit integer
  decoding is tried before floating-point decoding (MUST,
  `decode-precedence`, see Conformance Test Vector 016).
- **Concurrent access**: All seven pieces are stateless value types or
  static namespaces over immutable data (the date helper's four formatters
  are built once and never mutated, per `formatters-built-once`), except
  the shared markdown-editing injection point, which is confined to a
  single execution context and thus serialized rather than raced — none of
  these seven pieces themselves introduce a shared mutable variable a
  second call could observe mid-mutation. The closure-taking error
  normalizer MUST run its body under the caller's own execution context
  rather than a fixed one (see Platform Notes), so two concurrent callers on
  different execution contexts each run fully isolated within their own
  context; nothing in this piece coordinates between them, since
  coordinating unrelated callers is not this helper's job.
- **Error states**: Normalizing an error MUST convert any non-normalized
  error into an "unexpected" case carrying its string description, so no
  error this boundary sees is ever dropped silently (MUST,
  `wrap-maps-other-errors-to-unexpected`). Parsing a JSON document value
  MUST convert any decoding failure into a validation error carrying a
  human-readable message rather than letting the raw decoding error escape
  (MUST, `parse-wraps-decoding-failure-as-validation`). A cancellation
  signal thrown into the closure-taking error normalizer is not
  special-cased: it is wrapped into an "unexpected" case exactly like any
  other non-normalized error, per `wrap-maps-other-errors-to-unexpected` —
  the source draws no distinction between cancellation and any other thrown
  error.
- **Offline or disconnected state**: None of the seven given pieces make a
  network call, define a timeout, or define retry/backoff behavior of
  their own; the error normalizer normalizes whatever error a caller's own
  network call produces, but the network call itself, and any
  offline/connectivity handling around it, is outside these seven pieces
  (fact, not a gap — a thrown error is reported via normalization, not
  lost, just with no time bound or automatic retry defined at this layer).

