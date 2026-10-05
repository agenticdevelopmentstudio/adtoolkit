
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-prefs-001 | defaults-and-clamp | empty settings table | cutoff 900 s, granularity `day`, rounding 15 `up`, rate 0, `USD`, cap 28800 s, track-unassigned true |
| billing-prefs-002 | defaults-and-clamp | stored idle cutoff `0` | 60 s (clamped to 1 minute) |
| billing-prefs-003 | defaults-and-clamp | stored idle cutoff `9999` | 28800 s (clamped to 480 minutes) |
| billing-prefs-004 | granularity-fallback | stored granularity `weekly` | `day` |
| billing-prefs-005 | read-failure-throws | settings read throws | `snapshot` throws |
| billing-prefs-006 | apply-allow-list | `apply` with a billing key and an unrelated key | only the billing key is stored |
| billing-prefs-007 | cutoff-change-resets | `apply` changing the idle cutoff from 15 to 30 | derivation state of derived sessions is reset |
| billing-prefs-008 | cutoff-change-resets | `apply` changing only the currency | derivation state is not reset |
| billing-prefs-009 | units | snapshot with cutoff 900 s and cap 28800 s | `wireForm` has 15 minutes and 8 hours |

