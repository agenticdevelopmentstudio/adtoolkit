
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| expiring-memo-001 | serves-fresh-entry, expires-at-ttl | Memo with a 60-second time-to-live; read key `k` at t=0 (compute returns 1), at t=59, and at t=60 (compute returns 2). | t=0 returns 1; t=59 returns 1 without computing; t=60 computes and returns 2 (test: testServesTheStoredValueUntilItExpires). |
| expiring-memo-002 | clock-backwards-expires | Store key `k` at the start time, then read it one second before the start time with a compute returning 2. | Returns 2; the earlier entry was not trusted. |
| expiring-memo-003 | failed-compute-caches-nothing | Read key `k` with a compute that throws. | The error reaches the caller and the count stays 0. |
| expiring-memo-004 | capacity-evicts-oldest | Capacity 2; store keys `a`, `b`, `c` at increasing times, all still fresh. | The count is 2 and `a`, the oldest, is dropped; reading `a` computes again. |
| expiring-memo-005 | remove-all | Store two keys, then remove all. | The count is 0. |
| expiring-memo-006 | constructor-contract | Construct a memo with capacity 0. | Rejected as a programmer error. |
| expiring-memo-007 | sweep-on-store | Store `a`, advance past the time-to-live, then store `b`. | `a` is swept; the count is 1. |

