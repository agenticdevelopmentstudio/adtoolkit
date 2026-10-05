
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-derivation-001 | no-activity-no-runs | no timestamps | empty |
| billing-derivation-002 | single-event | one event at minute 0; session not active | one run, start = end = minute 0, 0 seconds |
| billing-derivation-003 | split-on-gap | events at minutes 0, 5, 10, 14, 20; cutoff 15 | one run, 0 to 20, 1200 seconds |
| billing-derivation-004 | split-on-gap | events at 0, 10, 40, 45 | two runs; the first ends at minute 10 (600 seconds) |
| billing-derivation-005 | split-on-gap | events at 0 and 15 (gap equals cutoff) | one run |
| billing-derivation-006 | open-final-run | events at 0, 10; active; now minute 15 | one open run, empty `endedAt`, 0 seconds |
| billing-derivation-007 | open-final-run | events at 0, 10; active; now minute 40 | run closed at minute 10 |
| billing-derivation-008 | open-final-run | events at 0, 10; not active; now minute 12 | run closed at minute 10 |
| billing-derivation-009 | first-run-lead-in | events at 10, 15; session start minute 0 | first run starts at minute 0, 900 seconds |
| billing-derivation-010 | first-run-lead-in | events at 40, 45; session start minute 0 | first run starts at minute 40 |
| billing-derivation-011 | first-run-lead-in | events at 10, 15, 60, 65; session start minute 0 | second run starts at minute 60 |
| billing-derivation-012 | first-run-lead-in | events at 0, 5; session start minute 3 | first run starts at minute 0 |
| billing-derivation-013 | parse-sort-dedupe | events at 20, 0, 10 | one run, 0 to 20 |
| billing-derivation-014 | malformed-now-closes | events at 0, 10; active; now `garbage` | run closed at minute 10 |
| billing-derivation-015 | cutoff-default | cutoff 0 with a 14-minute gap | one run (default cutoff applies) |

