
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-server-monitor-overall-001 | empty-statuses-is-unknown | The base rollup given an empty list | `'unknown'` |
| status-server-monitor-overall-002 | all-healthy-is-operational | ...given `['healthy', 'healthy']` | `'operational'` |
| status-server-monitor-overall-003 | any-down-or-degraded-is-degraded | ...given `['healthy', 'degraded']` | `'degraded'` |
| status-server-monitor-overall-004 | any-down-or-degraded-is-degraded | ...given `['healthy', 'down']` | `'degraded'` |
| status-server-monitor-overall-005 | all-down-is-major-outage, compute-overall-check-order | ...given `['down', 'down']` | `'major_outage'` — this input also satisfies any-down-or-degraded-is-degraded's condition, so this vector confirms check-order's precedence rather than only the final value |
| status-server-monitor-overall-006 | non-endpoint-problem-degrades-operational, public-overall-base | The public headline fold given `['healthy', 'healthy']` and a non-endpoint-problem flag of `true` | `'degraded'` |
| status-server-monitor-overall-007 | no-problem-leaves-base-unchanged | ...given `['healthy', 'healthy']` and a flag of `false` | `'operational'` |
| status-server-monitor-overall-008 | non-endpoint-problem-degrades-operational, non-endpoint-problem-never-escalates-past-degraded | ...given `['healthy']` and a flag of `true` | `'degraded'` — a non-endpoint problem never manufactures a full outage |
| status-server-monitor-overall-009 | non-endpoint-problem-never-overrides-major-outage | ...given `['down', 'down']` and a flag of `true` | `'major_outage'` — an all-endpoints-down verdict stands even with non-endpoint problems |
| status-server-monitor-overall-010 | non-endpoint-problem-never-overrides-existing-degraded | ...given `['healthy', 'down']` and a flag of `true` | `'degraded'` — an already-degraded endpoint rollup is unchanged by a non-endpoint problem |
| status-server-monitor-overall-011 | non-endpoint-problem-never-lifts-unknown | ...given an empty list and a flag of `true` | `'unknown'` — an unknown (no-signal) rollup is never lifted to degraded by a problem flag |
| status-server-monitor-overall-012 | overall-status-values | The four literals returned across the base rollup's and the public headline fold's branches | each is one of `'operational'`, `'degraded'`, `'major_outage'`, `'unknown'` — traced to the overall-status vocabulary's own declaration and the return literals used throughout the source |
| status-server-monitor-overall-013 | health-status-input | The per-endpoint list's element type is declared as the health vocabulary | construction-time rejection of an `"unknown"` element — traced to that declaration and the health vocabulary's three-value union; no runtime test exercises this since the type system enforces it at construction time |
| status-server-monitor-overall-014 | pure-synchronous-functions | Two sequential, independent calls to the base rollup given `['down']`, then again given `['down']` | both calls return `'degraded'` with neither call's result affected by the other — traced to the absence of any module-level mutable state or suspension point in the source |
| status-server-monitor-overall-015 | exported-surface | Import the base rollup, the public headline fold, and the overall-status type together | the import resolves all three names — traced to each declaration being exported |

