
- **namespace-shape**: The JSONC preprocessor MUST hold no instance state
  and no shared mutable state, and MUST expose its behavior only through
  operations callable without constructing or holding an instance of it.
- **no-side-effects**: None of the strip operation, the parse-to-object
  operation, or the normalize-to-strict-JSON operation MUST perform file,
  network, process, or notification I/O — each operates only on its
  parameter and returns a value or throws.
- **stateless-concurrency-safety**: The JSONC preprocessor MUST be safe to
  call concurrently from any thread with no synchronization required by the
  caller, because it holds nothing that one call could observe or mutate
  while another call is in progress.
- **strip-comment-removal**: The strip operation MUST remove every `//`
  line comment and every `/* … */` block comment from the input text before
  returning.
- **strip-trailing-comma-removal**: The strip operation MUST blank —
  overwrite with a single space, not delete — any comma that has only
  whitespace between it and the next `}` or `]`, and MUST run this pass
  only after comment removal, so a comma exposed by removing a comment is
  also caught.
- **strip-string-awareness**: Both the comment scanner and the
  trailing-comma scanner MUST track whether the current position is inside
  a double-quoted string, honoring a backslash escape immediately before a
  quote or another backslash, and MUST NOT treat `//`, `/*`, or `,` as
  syntactically significant while inside a string.
- **line-comment-stops-at-newline**: A `//` line comment MUST consume
  characters up to, but not including, the next newline character, so the
  newline itself MUST still appear in the output.
- **block-comment-unterminated-consumes-rest**: An unterminated `/* … */`
  block comment MUST consume every remaining character in the document,
  with no closing-delimiter recovery attempted.
- **jsonobject-tries-encodings-in-order**: The parse-to-object operation
  MUST attempt to decode the input bytes as text using, in this exact
  order, six candidate encodings — UTF-8, UTF-16, UTF-16 big-endian, UTF-16
  little-endian, UTF-32 big-endian, UTF-32 little-endian — skipping to the
  next candidate whenever decoding that candidate fails.
- **jsonobject-bom-stripped**: For each candidate encoding that decodes
  successfully, the parse-to-object operation MUST remove a leading U+FEFF
  byte-order-mark character from the decoded text before stripping
  comments and commas.
- **jsonobject-first-parseable-candidate-wins**: The parse-to-object
  operation MUST return the object graph produced by the first candidate
  encoding whose byte-order-mark-stripped, comment/comma-stripped text
  successfully parses as JSON, and MUST NOT attempt any further candidate
  once one has succeeded.
- **jsonobject-rejects-top-level-fragments**: The parse-to-object operation
  MUST reject a document whose root value is not a JSON object or array; a
  top-level scalar value is never accepted from any candidate, nor from the
  final fallback attempt.
- **jsonobject-fallback-on-raw-bytes**: When no candidate encoding yields
  text that both decodes and parses, the parse-to-object operation MUST
  attempt to parse the original, untransformed bytes directly as JSON, and
  MUST propagate whatever error that attempt throws to the caller
  unchanged.
- **jsondata-passthrough-when-already-strict**: The normalize-to-strict-JSON
  operation MUST return the input bytes unchanged, performing no
  transformation and no re-serialization, whenever those bytes already
  parse directly as JSON — including when the root value is a top-level
  scalar.
- **jsondata-reencodes-when-not-strict**: When that direct parse fails, the
  normalize-to-strict-JSON operation MUST run the parse-to-object operation
  on the input bytes and MUST re-serialize the resulting object graph as
  JSON, returning that re-serialized result.
- **jsondata-propagates-jsonobject-errors**: The normalize-to-strict-JSON
  operation MUST propagate, unmodified, whatever error the parse-to-object
  operation throws when the re-encode path is taken.
- **candidate-list-is-fixed**: The six-encoding list MUST be fixed and MUST
  NOT be configurable by a caller — neither the parse-to-object operation
  nor the normalize-to-strict-JSON operation accepts an encoding-list
  parameter.

