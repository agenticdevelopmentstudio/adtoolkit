
- **Null / empty input**: The strip operation on empty input MUST return
  empty output — there is nothing for either scanner to act on. The
  parse-to-object operation on empty bytes MUST throw: the first candidate
  encoding decodes the empty bytes to empty text, which strips to empty
  text and fails to parse as JSON; every other candidate encoding either
  fails to decode zero bytes or produces the same empty, unparseable text,
  so every candidate is exhausted and the final fallback attempt on the
  empty bytes also throws, propagating to the caller — this is a MUST,
  since nothing in the design special-cases an empty payload.
- **Boundary values**: The scanners impose no maximum input length; the
  comment scanner and the trailing-comma scanner MUST each make one linear
  pass over every character of the input regardless of size, with no early
  exit and no configurable ceiling — a caller passing an arbitrarily large
  input MUST have every character considered by both scanners. A document
  consisting of a single unmatched `"` (an opened-but-never-closed string)
  MUST leave both scanners inside a string for the remainder of the text,
  meaning any `//`, `/*`, or trailing comma after that point MUST be
  preserved rather than treated as syntax, and the resulting document MUST
  then fail to parse (the mechanism is
  **block-comment-unterminated-consumes-rest**'s sibling case, not a
  separate one — an unterminated string and an unterminated comment both
  simply run to the end of the text).
- **Concurrent access**: Per **stateless-concurrency-safety**, the JSONC
  preprocessor MUST behave identically under any number of concurrent
  calls, since it holds no state of any kind — this is not a caveat but
  the direct consequence of exposing behavior with no shared state at all.
- **Error states**: A document that fails to decode under every candidate
  encoding, or that decodes but fails to parse under every candidate after
  stripping, MUST cause the parse-to-object operation to throw the same
  error the underlying JSON parser raises for the caller's original,
  unmodified bytes (**jsonobject-fallback-on-raw-bytes**) — nothing wraps,
  annotates, or replaces that error, and no partial or best-effort result
  is ever returned. The normalize-to-strict-JSON operation MUST propagate
  that same error unchanged when its re-encode path is taken
  (**jsondata-propagates-jsonobject-errors**).
- **Offline / disconnected state**: Not applicable — the JSONC preprocessor
  performs no network I/O of any kind (**no-side-effects**); it operates
  only on the text or bytes a caller already holds in memory.

