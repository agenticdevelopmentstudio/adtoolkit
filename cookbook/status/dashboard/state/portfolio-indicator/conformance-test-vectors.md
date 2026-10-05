
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| portfolio-001 | mapped-verdict, snapshot-null-not-stale | `snapshot: null`, `offline: false`, `blind: false`, board `{ indicator: "operational", problems: [] }` | `pillKey` is `"ok"`, `count` is `0` |
| portfolio-002 | unknown-when-no-board, count-no-board, board-null-trusted | `snapshot: null`, `offline: false`, `blind: false`, `board: null` | `pillKey` is `"unknown"`, `count` is `0` |
| portfolio-003 | unknown-when-offline, count-from-board | `offline: true`, board `{ indicator: "operational", problems: [p1] }` | `pillKey` is `"unknown"`, `count` is `1` |
| portfolio-004 | unknown-when-blind | `blind: true`, `offline: false`, board `{ indicator: "degraded", problems: [p1, p2] }` | `pillKey` is `"unknown"`, `count` is `2` |
| portfolio-005 | mapped-verdict | fresh snapshot, board `{ indicator: "degraded", problems: [p1, p2] }` | `pillKey` is `"warn"`, `count` is `2` |
| portfolio-006 | mapped-verdict | fresh snapshot, board `{ indicator: "outage", problems: [p1] }` | `pillKey` is `"down"`, `count` is `1` |
| portfolio-007 | unknown-when-snapshot-stale, snapshot-stale-rule, freshness-window, freshness-threshold | snapshot `{ lastCycleAt: T, generatedAt: T + 301,000 ms, probeIntervalMs: 60,000 }`, board `{ indicator: "operational", problems: [] }` | Stale window is 300,000 ms, lag 301,000 ms, verdict `"stale"`: `pillKey` is `"unknown"`, `count` is `0` |
| portfolio-008 | freshness-threshold | snapshot `{ lastCycleAt: T, generatedAt: T + 300,000 ms, probeIntervalMs: 60,000 }`, board `{ indicator: "operational" }` | Lag equals window, verdict `"fresh"`: `pillKey` is `"ok"` |
| portfolio-009 | freshness-window | snapshot `{ lastCycleAt: T, generatedAt: T + 400,000 ms, probeIntervalMs: 120,000 }`, board `{ indicator: "operational" }` | Window is 600,000 ms, verdict `"fresh"`: `pillKey` is `"ok"` |
| portfolio-010 | freshness-threshold, unknown-when-snapshot-stale | snapshot `{ lastCycleAt: T, generatedAt: T + 901,000 ms, probeIntervalMs: 60,000 }`, board `{ indicator: "operational" }` | Verdict `"very-stale"`: `pillKey` is `"unknown"` |
| portfolio-011 | freshness-no-probe, snapshot-stale-rule | snapshot `{ lastCycleAt: null, generatedAt: T }`, board `{ indicator: "operational" }` | Verdict `"fresh"`: `pillKey` is `"ok"` |
| portfolio-012 | freshness-unparseable | snapshot `{ lastCycleAt: "not-a-date", generatedAt: T }`, board `{ indicator: "operational" }` | Invalid lag, verdict `"fresh"`: `pillKey` is `"ok"` |
| portfolio-013 | board-null-trusted, independent-feeds | The board state fed a board `{ indicator: "operational", problems: [] }` whose `generatedAt` is `BOARD_STALE_MS + 5,000` ms old; Live Snapshot inert (`snapshot: null`, `offline: false`, `blind: false`) | `pillKey` is `"unknown"`, and the global panel sharing the same cache context shows "status unknown" |
| portfolio-014 | no-memoisation | Evaluate with board `{ indicator: "operational" }` (`pillKey` is `"ok"`), then re-evaluate with `board: null` | Second evaluation returns `pillKey` `"unknown"`, not `"ok"` |
| portfolio-015 | hook-signature, no-text-output | Any input | The returned object's own keys are exactly `pillKey` and `count` |

