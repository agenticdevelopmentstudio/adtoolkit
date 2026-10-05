
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| lru-cache-001 | read-marks-used | Capacity 2; store `a`=1, then read `a`, then read `b`. | Returns 1 for `a` and nothing for `b` (test: testStoresAndReturnsValues). |
| lru-cache-002 | overflow-evicts-lru | Capacity 2; store `a`, `b`, read `a`, store `c`. | `b` is evicted; `a` and `c` remain; count is 2 (test: testOverflowEvictsTheLeastRecentlyUsed). |
| lru-cache-003 | peek-is-not-use | Capacity 2; store `a`, `b`, peek `a`, store `c`. | `a` is evicted because the peek did not refresh it; `b` is still held. |
| lru-cache-004 | overwrite-does-not-evict | Capacity 2; store `a`=1, `b`=2, then store `a`=10. | Count is 2; `a` is 10 and `b` is 2 (test: testOverwritingAKeyDoesNotEvict). |
| lru-cache-005 | remove-and-clear | Remove key `a`, then remove all. | `a` is no longer held; the count is 0 (test: testRemoval). |
| lru-cache-006 | lock-guarded, count-reported | Hammer a capacity-16 cache with concurrent stores and reads from many threads. | The count never exceeds 16 (test: testConcurrentUseStaysWithinCapacity). |
| lru-cache-007 | constructor-contract | Construct a cache with capacity 0. | Rejected as a programmer error. |

