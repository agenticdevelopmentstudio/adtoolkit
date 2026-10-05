
- **signature**: the query-match operation MUST take two text values, `haystack` and `query`, and MUST return a true-or-false result.
- **synchronous-result**: the operation MUST return its result synchronously, with no promise, callback or deferred work.
- **no-side-effects**: the operation MUST NOT mutate its arguments, keep state between calls, or perform I/O. The same inputs MUST always give the same result.
- **query-trim**: The operation MUST remove leading and trailing whitespace from `query` before any other processing.
- **empty-query-matches-all**: When `query` is empty or only whitespace, the operation MUST return true for every `haystack`, including an empty `haystack`.
- **case-insensitive**: The operation MUST lowercase both `query` and `haystack` using locale-independent default case mapping, not a locale-aware case mapping, before comparing them.
- **tokenization**: The operation MUST split the trimmed, lowercased query into tokens on runs of one or more whitespace characters. A run of several spaces, tabs or newlines MUST count as one separator and MUST NOT produce an empty token.
- **token-and**: The operation MUST return true only when every token appears in the lowercased `haystack`. It MUST return false as soon as any one token is absent.
- **substring-anywhere**: A token MUST match at any position in `haystack`, including inside a word or across punctuation such as `.`. The operation MUST NOT require a word boundary or a prefix match.
- **literal-token**: Each token MUST be compared as a literal substring. Characters such as `.`, `*` or `(` MUST NOT be read as pattern syntax.
- **order-independent**: The result MUST NOT depend on the order of the tokens in `query`, or on where the tokens occur in `haystack` relative to each other.
- **overlap-allowed**: The operation MUST let several tokens match the same or overlapping characters of `haystack`. A duplicated token MUST NOT need a second occurrence.
- **haystack-untrimmed**: The operation MUST NOT trim or tokenize `haystack`. Its whitespace and punctuation stay part of the searched text.
- **no-normalization**: The operation MUST NOT apply Unicode normalization, diacritic folding or any fuzzy matching. Canonically equivalent strings in different normal forms do not match unless their code points match after lowercasing.
- **string-precondition**: Callers MUST pass text values for both arguments. The operation does no runtime type check; passing a value that is not text is a caller precondition violation, and its behavior in that case is implementation-defined rather than specified.
- **no-errors-for-strings**: For any two text-value arguments, the operation MUST NOT throw.

