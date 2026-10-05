
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| utf8-search-001 | contains-bytes | Search a line for the needle `"type":"summary"` (quote characters included). | True when the line contains it (test: testFindsANeedleByItsBytes). |
| utf8-search-002 | exact-for-any-needle | Search a line for the bytes of `résumé`. | True when present, since multi-byte characters match exactly (test: testFindsANeedleByItsBytes). |
| utf8-search-003 | contains-bytes | Search a line for `assistant` when absent. | False (test: testFindsANeedleByItsBytes). |
| utf8-search-004 | empty-needle | Search any line for the empty needle. | True (test: testFindsANeedleByItsBytes). |
| utf8-search-005 | empty-haystack | Search the empty string for `x`. | False (test: testFindsANeedleByItsBytes). |
| utf8-search-006 | string-needle-overload | Search the same line using the string form and the byte form of one needle. | The same answer both ways. |

