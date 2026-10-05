
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| raw-setting-001 | bool-true-spellings | Read `" YES "`, `"On"`, `"1"` with default false. | True for each (test: testBoolReadsEverySpellingAndFallsBackOnGarbage). |
| raw-setting-002 | bool-false-spellings | Read `"off"`, `"No"`, `"0"` with default true. | False for each. |
| raw-setting-003 | bool-fallback | Read absent, empty and `"maybe"` with default true, then with default false. | The default each time. |
| raw-setting-004 | int-clamps-to-range | Read `"500"` with range 1 to 100 and default 10. | 100 (test: testIntClampsIntoRangeAndFallsBackWhenAbsent). |
| raw-setting-005 | int-parses-trimmed, int-default-not-clamped | Read absent, `"abc"` and `"1.5"` with range 1 to 100 and default 10. | 10 each time. |
| raw-setting-006 | string-trims, string-fallback | Read `"  hello "`, `"   "` and absent with default `x`. | `hello`, `x`, `x` (test: testStringTrimsAndFallsBackWhenEmpty). |

