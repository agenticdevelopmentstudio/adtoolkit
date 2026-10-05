
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-server-monitor-deploy-status-001 | vercel-deploy-substate-mapping | The Vercel phase mapper given ready state `READY`, substate `PROMOTED`, target `production` | `{ build phase: 'built', deploy phase: 'deployed' }` |
| status-server-monitor-deploy-status-002 | vercel-error-to-failed | ...given ready state `ERROR`, no substate, no target | `{ build phase: 'failed', deploy phase: 'none' }` |
| status-server-monitor-deploy-status-003 | vercel-deploy-production-gated | ...given ready state `READY`, no substate, no target (non-production) | `{ build phase: 'built', deploy phase: 'none' }` |
| status-server-monitor-deploy-status-004 | vercel-canceled-deleted-to-canceled | ...given ready state `CANCELED`, no substate, no target | `{ build phase: 'canceled', deploy phase: 'none' }` |
| status-server-monitor-deploy-status-005 | vercel-fallback-to-building | ...given ready state `BUILDING`, no substate, no target | `{ build phase: 'building', deploy phase: 'none' }` |
| status-server-monitor-deploy-status-006 | vercel-queued-to-queued | ...given ready state `QUEUED`, no substate, no target | `{ build phase: 'queued', deploy phase: 'none' }` |
| status-server-monitor-deploy-status-007 | vercel-deploy-substate-mapping | ...given ready state `READY`, substate `ROLLING`, target `production` | `{ build phase: 'built', deploy phase: 'deploying' }` |
| status-server-monitor-deploy-status-008 | railway-success-crashed | The Railway phase mapper given status `SUCCESS` | `{ build phase: 'built', deploy phase: 'deployed' }` |
| status-server-monitor-deploy-status-009 | railway-failed | ...given status `FAILED` | `{ build phase: 'failed', deploy phase: 'none' }` |
| status-server-monitor-deploy-status-010 | railway-building-initializing | ...given status `BUILDING` | `{ build phase: 'building', deploy phase: 'none' }` |
| status-server-monitor-deploy-status-011 | railway-deploying | ...given status `DEPLOYING` | `{ build phase: 'built', deploy phase: 'deploying' }` |
| status-server-monitor-deploy-status-012 | railway-removed-skipped | ...given status `REMOVED` | `{ build phase: 'canceled', deploy phase: 'none' }` |
| status-server-monitor-deploy-status-013 | railway-success-crashed | ...given status `CRASHED` | `{ build phase: 'built', deploy phase: 'deployed' }` — a runtime crash is not a deploy failure |
| status-server-monitor-deploy-status-014 | combined-status-deployed-success | The combining function given `{ build phase: 'built', deploy phase: 'deployed' }` | `'success'` |
| status-server-monitor-deploy-status-015 | combined-status-failed-precedence | ...given `{ build phase: 'failed', deploy phase: 'none' }` | `'failed'` |
| status-server-monitor-deploy-status-016 | combined-status-default-building | ...given `{ build phase: 'building', deploy phase: 'none' }` | `'building'` |
| status-server-monitor-deploy-status-017 | combined-status-queued | ...given `{ build phase: 'queued', deploy phase: 'none' }` | `'queued'` |
| status-server-monitor-deploy-status-018 | combined-status-canceled | ...given `{ build phase: 'canceled', deploy phase: 'none' }` | `'canceled'` |
| status-server-monitor-deploy-status-019 | combined-status-built-staged-success | ...given `{ build phase: 'built', deploy phase: 'none' }` | `'success'` |
| status-server-monitor-deploy-status-020 | combined-status-deploying-building | ...given `{ build phase: 'built', deploy phase: 'deploying' }` | `'building'` |
| status-server-monitor-deploy-status-021 | combined-status-unknown-precedence | ...given `{ build phase: 'unknown', deploy phase: 'none' }`; given `{ build phase: 'built', deploy phase: 'unknown' }` | Both `'unknown'` — an expired lifecycle never re-reads as building |
| status-server-monitor-deploy-status-022 | combined-status-evaluation-order, combined-status-failed-precedence | ...given `{ build phase: 'unknown', deploy phase: 'failed' }` | `'failed'` — a failure verdict still wins over an expired other lifecycle |
| status-server-monitor-deploy-status-023 | crunchy-bad-state-detection, crunchy-no-build-lifecycle | The Crunchy Bridge phase mapper given state `ready`, not suspended | `{ build phase: absent, deploy phase: 'deployed' }` |
| status-server-monitor-deploy-status-024 | crunchy-bad-state-detection | ...given state `ready`, suspended | `{ build phase: absent, deploy phase: 'failed' }` |
| status-server-monitor-deploy-status-025 | crunchy-bad-state-detection | ...given state `failed`, `creation_failed`, and `suspended` in turn, none suspended | All three `{ build phase: absent, deploy phase: 'failed' }` |
| status-server-monitor-deploy-status-026 | crunchy-healthy-default | ...given state `restarting`; given state `destroying`, neither suspended | Both `{ build phase: absent, deploy phase: 'deployed' }` — routine maintenance is not a problem |
| status-server-monitor-deploy-status-027 | crunchy-healthy-default | ...given an empty state string; given state `weird_unknown`, neither suspended | Both `{ build phase: absent, deploy phase: 'deployed' }` — an unrecognized state is not assumed bad |
| status-server-monitor-deploy-status-028 | is-in-flight-definition, is-in-flight-null-safe | The in-flight check given (`building`, `none`); given (`built`, `deployed`); given (an absent build phase, `deployed`) | `true`; `false`; `false` |
| status-server-monitor-deploy-status-029 | in-flight-sql-shape, in-flight-sql-default-prefix | The in-flight SQL-fragment builder with no argument | Exactly `"(build_phase IN ('building', 'queued') OR deploy_phase = 'deploying')"`, traced directly to the function body (no test asserts the literal string; see Compliance) |
| status-server-monitor-deploy-status-030 | collapse-build-sql | The build-phase collapse builder given the terminal value `canceled` | Exactly `"CASE WHEN build_phase IN ('building', 'queued') THEN 'canceled' ELSE build_phase END"`, traced directly to the function body |
| status-server-monitor-deploy-status-031 | is-in-flight-definition | The in-flight check as computed by each of the two independently maintained implementations, for every (build phase, deploy phase) pair over the full cross-product | All pairs equal |
| status-server-monitor-deploy-status-032 | combined-status-evaluation-order | The combining function as computed by each of the two independently maintained implementations, for every (build phase, deploy phase) pair over the full cross-product | All pairs equal |

