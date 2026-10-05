
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-timer-001 | start-closes-others | timer A running; start B at `now` | A closed at `now`; B running; one transaction |
| billing-timer-002 | start-closes-others | insert of B fails | A still running |
| billing-timer-003 | start-resolves-project | request with no project, root `/app`, branch `main`, and `/app` mapped to project p1 | segment has project p1 and the matching repo id |
| billing-timer-004 | start-resolves-project | request names project p2 | project p2 is kept |
| billing-timer-005 | stop | timer started 10:00:00Z, stop at 10:30:00Z | closed, 1800 seconds |
| billing-timer-006 | stop-unknown | stop of `missing` | throws `unknownTimer` |
| billing-timer-007 | stop-not-running | stop of a closed segment | throws `notRunning` |
| billing-timer-008 | stop-all-manual-only | one manual timer and one derived run running | returns 1; the derived run is still running |
| billing-timer-009 | flag-runaways | manual timer running 9 hours, cap 8 hours | flagged `runaway`, returns 1, still running |
| billing-timer-010 | flag-runaways | manual timer running 7 hours, cap 8 hours | not flagged, returns 0 |
| billing-timer-011 | cap-non-positive | cap 0 | returns 0 |

