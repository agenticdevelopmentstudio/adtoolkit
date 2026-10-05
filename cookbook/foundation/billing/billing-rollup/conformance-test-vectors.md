
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-rollup-001 | group-key | day granularity, rate 12000 | group key `rate:12000` |
| billing-rollup-002 | group-key | run granularity, auto segment session s1 starting 2026-09-22T14:00:00Z | `s1|2026-09-22T14:00:00Z` |
| billing-rollup-003 | figures | segments of 300 s five times, rounding 15 `up` | raw 1500, billed 1800 |
| billing-rollup-004 | figures | billed 5400 s at 12000 cents per hour | amount 18000 |
| billing-rollup-005 | frozen-owner-supplement | owner billed, new segment same slot | new supplement entry pointing at the owner; owner unchanged |
| billing-rollup-006 | snapshot-figures | project default rate changes after entry written, then recompute | entry keeps its original rate |
| billing-rollup-007 | rollup-owned-only | locked entry | not recomputed |
| billing-rollup-008 | empty-entry-removed | auto entry whose segments were detached | entry deleted |
| billing-rollup-009 | save-entry-origin | edit changing only the description of an auto entry | origin stays `auto`; description marked edited |
| billing-rollup-010 | save-entry-origin | edit changing hours | origin `user` |
| billing-rollup-011 | save-entry-refusals | save with different `updatedAt` | throws `entryChanged` |
| billing-rollup-012 | save-entry-refusals | save of locked entry | throws `entryIsLocked` |
| billing-rollup-013 | set-status | unbilled to billed | entry locked; audit row (`status`, `unbilled`, `billed`) |
| billing-rollup-014 | set-status | billed to unbilled | entry unlocked; audit row written |
| billing-rollup-015 | delete-entry | entry with a billed supplement | throws `entryHasFrozenSupplements` |
| billing-rollup-016 | overview | USD and EUR entries | two currency rows; top-level is the first |
| billing-rollup-017 | assign-repository | empty root | returns 0 |

