
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| utc-timestamp-001 | wire-form | Write epoch seconds 0, 1,790,067,600 and -1. | `1970-01-01T00:00:00Z`, `2026-09-22T09:00:00Z` and `1969-12-31T23:59:59Z` (test: testWritesTheFixedWidthWireInstant). |
| utc-timestamp-002 | fractions-truncate | Write an instant at 1,790,067,600.999 seconds. | `2026-09-22T09:00:00Z` (test: testFractionsTruncate). |
| utc-timestamp-003 | days-ago | 14 days before a reference of `2026-09-22T09:00:00Z` (epoch 1,790,067,600). | `2026-09-08T09:00:00Z` (test: testDaysAgoIsWholeDaysBeforeTheReference). |
| utc-timestamp-004 | day-key | The day of `2026-09-23T04:30:00Z` (epoch 1,790,137,800) in America/Los_Angeles and in Europe/Berlin. | `2026-09-22` and `2026-09-23` (test: testTheDayIsTheLocalCalendarDay). |
| utc-timestamp-005 | fast-path-shapes, read-epoch-seconds | Read `2026-09-22T09:00:00.750Z`, `2026-09-22 09:00:00` and `2026-09-22T11:00:00+02:00`. | Epoch 1,790,067,600 for each; the offset form falls back to the shared parser (test: testReadsEveryStoredShape, which does not cover the SQLite millisecond form `2026-09-22 10:00:00.123`, read as epoch 1,790,071,200). |
| utc-timestamp-006 | fast-path-validates | Fast-path read of `2026-09-22T11:00:00+02:00` and `2026-13-22T09:00:00Z`. | The fast path declines each; the shared parser then decides (test: testTheFastPathRefusesWhatItCannotReadExactly, which does not exercise day-beyond-month or hour 24). |
| utc-timestamp-007 | canonical | Canonical of `2026-09-22T14:00:05.999Z` and `2026-09-22 14:00:05.123`. | `2026-09-22T14:00:05Z` for both, so neither sorts differently from the plain form of the same second (test: testCanonicalMakesInstantsComparableAsStrings). |
| utc-timestamp-008 | seconds-between | Seconds from `2026-09-22T14:00:00Z` to `2026-09-22T16:15:00Z`, the reverse pair, and from `nonsense`. | 8100, then 0 and 0 (test: testSecondsNeverGoNegative). |
| utc-timestamp-009 | adding | Add 1 to `2026-09-22T23:59:59Z`, and to `nonsense`. | `2026-09-23T00:00:00Z` and nothing (test: testAddingMovesByWholeSeconds). |

