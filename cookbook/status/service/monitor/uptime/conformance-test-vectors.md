
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-server-monitor-uptime-001 | uptime-percent-formula, uptime-percent-degraded-counts-as-up | The uptime-percentage calculation given a tally of `{ total: 100, healthy: 90, degraded: 5, down: 5 }` | `95` |
| status-server-monitor-uptime-002 | uptime-percent-no-data | The uptime-percentage calculation given a tally of `{ total: 0, healthy: 0, degraded: 0, down: 0 }` | `null` |
| status-server-monitor-uptime-003 | uptime-percent-formula | The uptime-percentage calculation given a tally of `{ total: 3, healthy: 1, degraded: 1, down: 1 }` | `66.67` (2 of 3 checks up, rounded to two decimal places) |
| status-server-monitor-uptime-004 | day-status-down-majority | The day-status classification given a tally of `{ total: 10, healthy: 2, degraded: 0, down: 8 }` | `"down"` (`8/10 = 0.8`, greater than `0.5`) |
| status-server-monitor-uptime-005 | day-status-down-minority | The day-status classification given a tally of `{ total: 10, healthy: 7, degraded: 0, down: 3 }` | `"degraded"` (`3/10 = 0.3`, not greater than `0.5`) |
| status-server-monitor-uptime-006 | day-status-degraded-only | The day-status classification given a tally of `{ total: 10, healthy: 8, degraded: 2, down: 0 }` | `"degraded"` |
| status-server-monitor-uptime-007 | day-status-healthy-default | The day-status classification given a tally of `{ total: 10, healthy: 10, degraded: 0, down: 0 }` | `"healthy"` |
| status-server-monitor-uptime-008 | day-status-no-zero-total-guard | The day-status classification given a tally of `{ total: 0, healthy: 0, degraded: 0, down: 0 }` | `"healthy"` (the default fall-through); contrast with vector 002, the identical input returning `null` from the uptime-percentage calculation |
| status-server-monitor-uptime-009 | overall-uptime-mean | The overall-uptime mean given `[{ uptimePercent: 100 }, { uptimePercent: 90 }]` | `95` |
| status-server-monitor-uptime-010 | overall-uptime-excludes-null | The overall-uptime mean given `[{ uptimePercent: 99 }, { uptimePercent: null }, { uptimePercent: 95 }]` | `97` (mean of `99` and `95` only; the divisor is `2`, not `3`) |
| status-server-monitor-uptime-011 | overall-uptime-no-data | The overall-uptime mean given an empty list | `null` |
| status-server-monitor-uptime-012 | overall-uptime-no-data | The overall-uptime mean given `[{ uptimePercent: null }]` | `null` |
| status-server-monitor-uptime-013 | uptime-percent-formula (caller integration) | A request for a 90-day uptime window against seeded per-day check rows for one configured endpoint | The first service's uptime percentage is `50` — integration evidence for the same formula reached through the route that calls it |
| status-server-monitor-uptime-014 | pure-computation, concurrency-safety | The uptime-percentage calculation and the day-status classification both called on the same tally `{ total: 10, healthy: 10, degraded: 0, down: 0 }`, repeated and interleaved with calls using other tallies | Every call returns the same value for the same input every time (`100` and `"healthy"`), and the tally's own fields are unchanged after any call |
| status-server-monitor-uptime-015 | counts-shape, health-status-return | The day-status classification's return value inspected across vectors 004–008 | Every returned value is one of exactly `"healthy"`, `"degraded"`, or `"down"` |

