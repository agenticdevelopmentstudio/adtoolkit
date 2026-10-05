
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| system-memory-monitor-001 | critical-precedence-over-warning | Compute the pressure level for a delivered event set containing only `critical`. | Returns `critical`. |
| system-memory-monitor-002 | critical-precedence-over-warning | Compute the pressure level for a delivered event set containing `warning` and `critical` (no `normal`). | Returns `critical` — critical wins over warning when both bits are set without `normal`. |
| system-memory-monitor-003 | warning-when-only-warning-set | Compute the pressure level for a delivered event set containing only `warning`. | Returns `warning`. |
| system-memory-monitor-004 | coalesced-normal-precedence | Compute the pressure level for a delivered event set containing only `normal`. | Returns `normal`. |
| system-memory-monitor-005 | coalesced-normal-precedence | Compute the pressure level for a delivered event set containing `warning` and `normal`. | Returns `normal` — a coalesced raise+fall latches the later, normal event rather than the raise. |
| system-memory-monitor-006 | coalesced-normal-precedence | Compute the pressure level for a delivered event set containing `critical` and `normal`. | Returns `normal`. |
| system-memory-monitor-007 | coalesced-normal-precedence | Compute the pressure level for a delivered event set containing `warning`, `critical`, and `normal`. | Returns `normal` even with all three bits set. |
| system-memory-monitor-008 | physical-ram-source | Construct a monitor and read its physical RAM. | Returns a value greater than `1,000,000,000` (the real host's physical RAM in bytes). |
| system-memory-monitor-009 | initial-pressure-level | Construct a fresh monitor and read its pressure level before any memory-pressure event has been delivered. | Returns `normal`, from the latch's default (not directly asserted by the test file but the sole possible value before the underlying subscription delivers its first event). |
| system-memory-monitor-010 | shared-singleton-instance | Read the shared instance twice from different call sites. | Both reads yield the identical instance, since the shared instance is created exactly once. |
| system-memory-monitor-011 | unmatched-mask-defaults-normal | Compute the pressure level for an empty delivered event set (not exercised by the test file; derived directly from the source). | Returns `normal`, the function's final fallthrough case. |

