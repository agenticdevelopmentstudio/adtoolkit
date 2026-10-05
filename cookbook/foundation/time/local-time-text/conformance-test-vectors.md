
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| local-time-text-001 | clock-text | Format 2026-09-22T14:05:00Z in UTC for en_US and en_GB. | Text starting `2:05` (the test asserts only the prefix, since the day-period spacing is the platform's) and exactly `14:05` (test: testTheClockFollowsTheLocale). |
| local-time-text-002 | parse-locale-first, parse-twenty-four-hour | Parse `2:05 PM` and `2pm` in en_GB, and `14:05` in en_US. | Clocks of 14:05, 14:00 and 14:05 (test: testEitherClockIsAcceptedWhenTyped, which does not cover `2:05pm`, `2 PM` or a bare `14`). |
| local-time-text-003 | parse-ambiguous-bare-time | Parse `2:05` in a 12-hour locale and in a 24-hour locale. | Two readings, 02:05 and 14:05, in the 12-hour locale; one, 02:05, in the 24-hour one (test: testABareTimeIsAmbiguousOnlyOnATwelveHourClock). |
| local-time-text-004 | nearest-instant | Reference `2026-09-22T23:55:00Z` in UTC; typed clock 00:10. | `2026-09-23T00:10:00Z`, on the next day, being nearest (test: testTheNearestInstantMayFallOnTheNextDay). |
| local-time-text-005 | start-of-day, integer-seconds-between | Start of `2026-09-22` in UTC; start of `someday`; seconds between the start and one hour later. | Epoch 1,790,035,200; nothing; 3600 (test: testStartOfDayAndSeconds). |
| local-time-text-006 | parse-not-a-time | Parse `not a time` (test: testEitherClockIsAcceptedWhenTyped), and the empty string (untested). | No readings. |

