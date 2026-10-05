
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| foundation-json-001 | strip-comment-removal, strip-string-awareness | `{ // the answer\n "a": 1 }` | Parses to `{"a": 1}` — the `//` comment is removed, the value survives. |
| foundation-json-002 | strip-comment-removal | A multi-line `/* … */` block comment plus an inline `/* and inline */` between two keys. | Parses to `{"a": 1, "b": 2}`. |
| foundation-json-003 | block-comment-unterminated-consumes-rest | `{"a": 1 /* oops }` | Throws — the open block comment swallows the rest of the document, leaving nothing left to parse. |
| foundation-json-004 | strip-string-awareness | `{"$schema": "https://example.com/schema.json"}` | Parses to `{"$schema": "https://example.com/schema.json"}` — the `//` inside the URL is not treated as a comment. |
| foundation-json-005 | strip-string-awareness | `{"a": "say \"hi\" // not a comment"}` | Parses to `{"a": "say \"hi\" // not a comment"}` — the escaped quotes keep the string open past them, and the `//` inside it is left alone. |
| foundation-json-006 | strip-string-awareness, strip-trailing-comma-removal | `{"a": "one, two", "b": 2}` | Parses to `{"a": "one, two", "b": 2}` — the comma inside the string value is not blanked. |
| foundation-json-007 | strip-string-awareness | `{"a": "back\\", "b": 2}` | Parses to `{"a": "back\\", "b": 2}` — the escaped backslash does not itself escape the closing quote. |
| foundation-json-008 | strip-trailing-comma-removal | `{ "a": 1, }` | Parses to `{"a": 1}`. |
| foundation-json-009 | strip-trailing-comma-removal | `{ "a": [1, 2, ] }` | Parses to `{"a": [1, 2]}`. |
| foundation-json-010 | strip-trailing-comma-removal, strip-comment-removal | `{ "a": [1, /* stale */] }` | Parses to `{"a": [1]}` — the comma is only trailing once the comment between it and `]` is gone, confirming comments are stripped before commas. |
| foundation-json-011 | line-comment-stops-at-newline | Perform the strip operation on `"// a\nb"`. | Returns `"\nb"` — the comment's own newline is preserved rather than consumed. |
| foundation-json-012 | jsonobject-tries-encodings-in-order, jsonobject-first-parseable-candidate-wins | A JSONC document with a `//` comment, encoded with UTF-16. | Parses to `{"a": 1}` — the UTF-8 candidate fails to decode or parse, and the UTF-16 candidate succeeds. |
| foundation-json-013 | jsonobject-bom-stripped | The three UTF-8 byte-order-mark bytes followed by `{"a": 1}`. | Parses to `{"a": 1}` — the byte-order mark is skipped rather than causing the document to be rejected. |
| foundation-json-014 | jsonobject-fallback-on-raw-bytes | `{"a": 1` (unterminated object). | Throws — nothing is repaired or invented; the caller learns the document is broken. |
| foundation-json-015 | jsonobject-fallback-on-raw-bytes, strip-comment-removal | `// nothing here\n` | Throws — every candidate encoding strips to an empty or comment-only document with nothing left to parse. |
| foundation-json-016 | jsonobject-rejects-top-level-fragments | Perform the parse-to-object operation on the bytes for `42` — a bare top-level number, already strict JSON. | Throws — a document whose root is a scalar is rejected even though the bytes are otherwise valid JSON. |
| foundation-json-017 | jsondata-passthrough-when-already-strict | Perform the normalize-to-strict-JSON operation on the bytes for `42`. | Returns those same bytes unchanged — the top-level scalar is accepted directly and the re-encode path never runs. |
| foundation-json-018 | jsondata-passthrough-when-already-strict | Perform the normalize-to-strict-JSON operation on the bytes for `{"a":1e3}`. | Returns the exact original bytes, byte-for-byte, including `1e3` — not a re-serialized `{"a":1000}` — because the passthrough check succeeds and no re-encode ever runs. |
| foundation-json-019 | jsondata-reencodes-when-not-strict | Perform the normalize-to-strict-JSON operation on the bytes for `{"a": 1, }` (a trailing comma, so not strict JSON). | Returns re-serialized bytes that parse to `{"a": 1}` — the bytes differ from the input because the trailing comma forced the parse-and-re-serialize path. |
| foundation-json-020 | jsondata-propagates-jsonobject-errors | Perform the normalize-to-strict-JSON operation on the bytes for `{"a": 1` (unterminated, and not strict). | Throws — the failure originates in the parse-to-object operation's fallback attempt and passes through unmodified. |
| foundation-json-021 | stateless-concurrency-safety | Issue fifty concurrent calls to the strip operation and the parse-to-object operation, each with a distinct input, from many threads at once. | Every call returns the result matching its own input, with no cross-talk between calls — there is no shared state for two calls to interleave through. |
| foundation-json-022 | no-side-effects | Call the parse-to-object and normalize-to-strict-JSON operations with valid JSONC bytes in a test with no filesystem, network, or notification observers configured. | The call succeeds or throws based only on the bytes given it; no file is created, no request is issued, no notification is posted. |
| foundation-json-023 | candidate-list-is-fixed | Attempt to write a call site passing an encoding list or a custom encoding to either operation. | Rejected before it can run — neither operation accepts such a parameter. |

