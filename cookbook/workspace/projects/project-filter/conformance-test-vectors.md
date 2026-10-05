
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| PF-001 | empty-query-yields-no-ranges | Finding ranges with an empty query against the text "whippet" | No ranges |
| PF-002 | all-occurrences-returned-left-to-right | Finding ranges with the query "hip" against the text "whippet" | One range: position 1, length 3 |
| PF-003 | case-insensitive-matching | Finding ranges with the query "WHIP" against the text "whippet" | One range: position 0, length 4 |
| PF-004 | all-occurrences-returned-left-to-right | Finding ranges with the query "ab" against the text "abcab" | Two ranges, in order: position 0 length 2, then position 3 length 2 |
| PF-005 | empty-text-yields-no-ranges | Finding ranges with the query "zz" against the text "whippet" | No ranges (no match found; exercises the same not-found path as an empty haystack) |
| PF-006 | matches-by-name-or-path-only | Checking a match for a repository record named "whippet" at path "/Users/someone/dev/whippet", with the query "hipp" | Match |
| PF-007 | matches-by-name-or-path-only | Checking a match for the same record, with the query "someone" | Match |
| PF-008 | matches-by-name-or-path-only | Checking a match for the same record, with the query "stenographer" | No match |
| PF-009 | empty-query-matches-every-repo | Checking a match for the same record, with an empty query | Match |
| PF-010 | non-overlapping-scan-advance | Finding ranges with the query "aa" against the text "aaa" | One range only: position 0, length 2 — the second, overlapping "aa" starting at position 1 is not reported |
| PF-011 | literal-substring-matching | Finding ranges with the query "." against the text "a.b.c" | Two ranges: position 1 length 1, then position 3 length 1 — matches the two literal periods only, never treated as a wildcard |
| PF-012 | ranges-loop-terminates | Finding ranges with the query "z" against a text of 10,000 repeated "a" characters | No ranges, and the scan returns control to the caller — it makes no forward progress past as many iterations as the text is long, regardless of input size |

