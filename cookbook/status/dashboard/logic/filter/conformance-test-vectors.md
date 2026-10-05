
Vectors 001 to 006 come straight from the assertions in the module's own test suite. The rest follow from the code.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| filter-001 | empty-query-matches-all | haystack `"anything"`, query `""` | `true` |
| filter-002 | empty-query-matches-all, query-trim | haystack `"anything"`, query `"   "` | `true` |
| filter-003 | case-insensitive, substring-anywhere | haystack `"staging.adh deploy failed"`, query `"ADH"` | `true` |
| filter-004 | token-and | haystack `"staging.adh"`, query `"prod"` | `false` |
| filter-005 | token-and, tokenization | haystack `"testing.admin.adh deploy failed"`, query `"testing failed"` | `true` |
| filter-006 | token-and | haystack `"testing.admin.adh deploy failed"`, query `"testing deployed"` | `false` (`deployed` is absent) |
| filter-007 | empty-query-matches-all | haystack `""`, query `""` | `true` |
| filter-008 | token-and | haystack `""`, query `"x"` | `false` |
| filter-009 | query-trim, tokenization, order-independent | haystack `"staging.adh"`, query `"  adh   staging "` | `true` |
| filter-010 | tokenization | haystack `"deploy failed"`, query `"deploy\tfailed"` (a tab separates the tokens) | `true` |
| filter-011 | literal-token, substring-anywhere | haystack `"staging.adh"`, query `"g.a"` | `true` |
| filter-012 | literal-token | haystack `"stagingXadh"`, query `"g.a"` | `false` (`.` is not a wildcard) |
| filter-013 | overlap-allowed | haystack `"adh"`, query `"adh adh a"` | `true` |
| filter-014 | haystack-untrimmed | haystack `"adh deploy"`, query `"hdep"` | `false` (the space in `haystack` breaks the substring, and a token never contains whitespace) |
| filter-015 | case-insensitive | haystack `"Deploy FAILED"`, query `"deploy failed"` | `true` |
| filter-016 | no-normalization | haystack is `café` with a precomposed `é` (U+00E9), query is `café` with `e` plus a combining acute accent (U+0065 U+0301) | `false` |
| filter-017 | case-insensitive, no-normalization | haystack `"İstanbul"` (capital dotted I, U+0130), query `"istanbul"` | `false` (default lowercasing turns U+0130 into `i` plus a combining dot U+0307) |
| filter-018 | no-side-effects | The query-match operation on haystack `"staging.adh"`, query `"adh"`, called twice with the same arguments | `true` both times, and both argument strings are unchanged |
| filter-019 | no-errors-for-strings | haystack `"a"`, query `"("` | `false` with no exception (`(` is not parsed as a pattern) |

