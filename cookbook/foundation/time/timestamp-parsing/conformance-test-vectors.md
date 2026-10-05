
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| timestamp-parsing-001 | three-shapes, fractional-equals-plain-plus-fraction | Parse `2026-04-14T10:00:00.500Z` and `2026-04-14T10:00:00Z`. | The first is the second plus 0.5 seconds (test: testFractionalMatchesPlainPlusFraction). |
| timestamp-parsing-002 | three-shapes, sqlite-is-utc | Parse `2026-04-14 10:00:00`. | The instant 2026-04-14T10:00:00Z, epoch 1776160800 (test: testSQLiteDateTimeParsedAsUTC). |
| timestamp-parsing-003 | empty-is-nothing | Parse the empty string. | Nothing (test: testEmptyAndGarbageAreNil). |
| timestamp-parsing-004 | unparseable-is-nothing | Parse `not a date` and `2026-13-99`. | Nothing (test: testEmptyAndGarbageAreNil). |
| timestamp-parsing-005 | try-order | Parse `2026-04-14T10:00:00Z`. | Parsed by the plain ISO shape after the fractional one declines. |
| timestamp-parsing-006 | three-shapes | Parse `2026-04-14T10:00:00+02:00`. | The instant 2026-04-14T08:00:00Z: a numeric zone offset is accepted by the ISO shape. |

