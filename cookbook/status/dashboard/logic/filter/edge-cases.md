
- **Empty or blank query**: An empty or whitespace-only `query` MUST match every `haystack` (filter-001, filter-002, filter-007). At the activity panel this means a cleared search box shows every row that passes the source filter.
- **Empty haystack**: An empty `haystack` MUST match only a blank query (filter-007, filter-008).
- **Repeated or mixed whitespace**: Extra spaces, tabs, newlines and other whitespace characters between tokens MUST collapse to single separators (filter-009, filter-010).
- **Pattern metacharacters**: Characters such as `.`, `*`, `(` and `[` MUST be matched literally and MUST NOT throw (filter-011, filter-012, filter-019).
- **Duplicate tokens**: A token repeated in `query` MUST NOT require repeated occurrences in `haystack` (filter-013).
- **Text spanning a haystack space**: Because tokens never contain whitespace, a token cannot match across a space in `haystack` (filter-014). Its only chance is a contiguous run with no whitespace.
- **Locale-sensitive case pairs**: Lowercasing is locale-independent, so Turkish dotted and dotless I pairs do not fold the way a Turkish user expects (filter-017). The source deliberately keeps case mapping locale-independent, so this MUST be kept in a conformant port.
- **Unicode normal forms**: Precomposed and decomposed forms of the same character MUST NOT match each other (filter-016). No normalization step exists.
- **Non-text arguments**: Outside static type checking, passing a value that is not text is a caller precondition violation (see **string-precondition**), and the one call site always passes text values.
- **Large inputs**: Cost grows with the number of tokens times the length of `haystack`, and both strings are lowercased again on every call. The operation sets no length limit, and the caller runs it once per row whenever its cached inputs change.
- **Concurrent access**: Not applicable. The operation is stateless, so calls cannot interleave.
- **Error states, offline, timeouts and cancellation**: Not applicable. The operation does no I/O and finishes synchronously, so there is nothing to time out, cancel or lose a connection to.

