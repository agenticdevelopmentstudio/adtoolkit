
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| billing-activity-cache-001 | merge-append-fast-path | `merging([30, 20], into: [10])` | `[10, 20, 30]` |
| billing-activity-cache-002 | merge-sorted-unique | `merging([5, 15, 15], into: [10, 20])` | `[5, 10, 15, 20]` |
| billing-activity-cache-003 | merge-sorted-unique | `merging([10, 20], into: [10, 20])` | `[10, 20]` |
| billing-activity-cache-004 | merge-empty-fresh | `merging([], into: [1, 2])` | `[1, 2]` |
| billing-activity-cache-005 | merge-sorted-unique | `merging([3, 1, 2], into: [])` | `[1, 2, 3]` |
| billing-activity-cache-006 | cursor-advance | first call reads after id 0 and returns lastId 40; second call | reads after id 40 |
| billing-activity-cache-007 | forget | call, `forget`, call again | second call reads after id 0 |
| billing-activity-cache-008 | bounded | 65 distinct sessions with capacity 64 | `count` is 64; the first session was evicted |

