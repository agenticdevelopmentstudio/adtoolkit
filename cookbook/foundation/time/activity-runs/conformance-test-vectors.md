
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| activity-runs-001 | split-at-idle-gap | Stamps 0, 60, 120, 1000, 1030 with idle gap 300. | Two spans: 0 to 120 and 1000 to 1030 (test: testSplitsAtEveryGapLongerThanTheIdleGap). |
| activity-runs-002 | equal-gap-does-not-split | Stamps 0 and 300 with idle gap 300. | One span from 0 to 300 (test: testAGapEqualToTheIdleGapDoesNotSplit). |
| activity-runs-003 | no-stamps-no-spans | No stamps. | No spans (test: testNoStampsIsNoSpans). |
| activity-runs-004 | close-run, streaming-splitter | Add 0 and 60, close the run, add 70. | Two spans: 0 to 60 and 70 to 70 (test: testTheSplitterClosesARunAtABoundaryTheStampsDontShow). |
| activity-runs-005 | union | Intervals 0 to 10, 5 to 15 and 15 to 20. | One span 0 to 20: overlapping and touching intervals merge (test: testUnionMergesOverlappingAndTouchingIntervals). |
| activity-runs-006 | union-length | Intervals 0 to 10 and 5 to 15. | Length 15, not 20 (test: testUnionLengthCountsOverlapOnce). |
| activity-runs-007 | union-ordering-only | Intervals of ISO strings `2026-01-01T10:00:00Z` to `2026-01-01T10:30:00Z` and `...10:20:00Z` to `...10:45:00Z`. | One span from `10:00:00Z` to `10:45:00Z` (test: testUnionWorksOnFixedWidthStrings). |

