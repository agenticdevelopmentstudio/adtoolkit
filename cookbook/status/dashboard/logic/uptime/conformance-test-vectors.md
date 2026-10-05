
Vectors 001–009 are the assertions in the implementation's test suite (see Platform Notes); the rest are derived from the source arithmetic.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| uptime-001 | uptime-degraded-counts-as-up, uptime-two-decimal-rounding | the uptime-percent function called with counts `total: 100`, `healthy: 90`, `degraded: 5`, `down: 5` | `95` |
| uptime-002 | uptime-null-when-no-checks | the uptime-percent function called with counts `total: 0`, `healthy: 0`, `degraded: 0`, `down: 0` | `null` |
| uptime-003 | day-down-majority | the day-status function called with counts `total: 10`, `healthy: 2`, `degraded: 0`, `down: 8` | `"down"` |
| uptime-004 | day-down-minority | the day-status function called with counts `total: 10`, `healthy: 7`, `degraded: 0`, `down: 3` | `"degraded"` |
| uptime-005 | day-degraded | the day-status function called with counts `total: 10`, `healthy: 8`, `degraded: 2`, `down: 0` | `"degraded"` |
| uptime-006 | day-healthy | the day-status function called with counts `total: 10`, `healthy: 10`, `degraded: 0`, `down: 0` | `"healthy"` |
| uptime-007 | overall-unweighted-mean | the overall-uptime-percent function called with services `uptimePercent: 100` and `uptimePercent: 90` | `95` |
| uptime-008 | overall-ignores-null | the overall-uptime-percent function called with services `uptimePercent: 99`, `uptimePercent: null`, `uptimePercent: 95` | `97` |
| uptime-009 | overall-null-when-no-data | the overall-uptime-percent function called with an empty list, and separately with one service whose `uptimePercent` is `null` | `null` for both |
| uptime-010 | uptime-two-decimal-rounding | the uptime-percent function called with counts `total: 3`, `healthy: 2`, `degraded: 0`, `down: 1` | `66.67` |
| uptime-011 | uptime-null-when-no-checks | the uptime-percent function called with counts `total: -1`, `healthy: 0`, `degraded: 0`, `down: 0` | `null` |
| uptime-012 | uptime-denominator-total, uptime-no-clamp | the uptime-percent function called with counts `total: 4`, `healthy: 5`, `degraded: 0`, `down: 0` | `125` |
| uptime-013 | day-down-minority | the day-status function called with counts `total: 10`, `healthy: 5`, `degraded: 0`, `down: 5` (exactly half down) | `"degraded"` |
| uptime-014 | day-down-checked-first | the day-status function called with counts `total: 10`, `healthy: 0`, `degraded: 9`, `down: 1` | `"degraded"` |
| uptime-015 | day-zero-total-with-down | the day-status function called with counts `total: 0`, `healthy: 0`, `degraded: 0`, `down: 1` | `"down"` |
| uptime-016 | day-healthy | the day-status function called with counts `total: 0`, `healthy: 0`, `degraded: 0`, `down: 0` | `"healthy"` |
| uptime-017 | overall-two-decimal-rounding | the overall-uptime-percent function called with services `uptimePercent: 33.33`, `uptimePercent: 33.33`, `uptimePercent: 33.34` | `33.33` |
| uptime-018 | overall-nan-propagates | the overall-uptime-percent function called with services `uptimePercent: NaN` and `uptimePercent: 90` | `NaN` |
| uptime-019 | service-input-shape, overall-unweighted-mean | the overall-uptime-percent function called with services `uptimePercent: 100` (plus an unrelated field recording 1000 checks) and `uptimePercent: 50` (plus an unrelated field recording 2 checks) | `75` (check volume has no effect) |
| uptime-020 | pure-functions | the uptime-percent function, the day-status function and the overall-uptime-percent function each called on frozen (immutable) counts and lists | No exception; inputs unchanged |

