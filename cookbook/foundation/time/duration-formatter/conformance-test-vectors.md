
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| duration-formatter-001 | hours-minutes | Format 8,100 seconds, 7,200 seconds, 2,700 seconds and 59 seconds. | `2h 15m`, `2h`, `45m`, `0m` (test: testHoursMinutes). |
| duration-formatter-002 | decimal-hours | Decimal hours for 8,100 seconds, and for 1,800 seconds. | `2.25` and `0.50` (test: testDecimalHours). |
| duration-formatter-003 | decimal-hours | Decimal hours for 1 second at 2 places. | `0.00`; for 10 seconds, `0.00`; for 18 seconds, `0.01` (test: testDecimalHoursRoundsHalfUp). |
| duration-formatter-004 | clock-form | Clock form for 8,100 and 90,000 seconds. | `2:15:00` and `25:00:00` (test: testClock). |
| duration-formatter-005 | negative-clamps-to-zero | Format -30 seconds in each form. | `0m`, `0.00`, `0:00:00` (test: testNegativeSecondsClampToZero). |
| duration-formatter-006 | parse-decimal-hours, parse-clock, parse-units | Parse `1.5`, `1:30`, `1h 30m`, `90m`, `.5`, `1,5`. | 5,400, 5,400, 5,400, 5,400, 1,800, 5,400 (test: testSecondsParsingAcceptsTheCommonForms). |
| duration-formatter-007 | parse-refuses-the-rest | Parse `-1`, `1:5`, `abc`, `1.2.3` and the empty string. | Nothing for each (test: testSecondsParsingRefusesWhatIsNotADuration). |

