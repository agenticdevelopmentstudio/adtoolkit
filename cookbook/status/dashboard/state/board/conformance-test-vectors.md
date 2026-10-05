
All vectors run this logic under a fresh shared cache with the live-frame feed mocked and the network stubbed (see Platform Notes). "Fresh" below means `generatedAt` = now and `dataAsOfMs` = now; `probeIntervalMs` is 60,000.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-board-001 | fetch-body-passthrough, verdict-current, reason-board-exclusive | Server returns a fresh board with one problem | `board` deep-equals the server payload; `reason` null (see Platform Notes) |
| use-board-002 | no-durable-state | Fresh board fetched successfully | No durable storage write occurs after `board` is non-null |
| use-board-003 | server-removal-propagates, refetch-field | First read has 1 problem; server switched to `problems: []`, `indicator: "operational"`; caller invokes `refetch` | `board.problems` becomes `[]` |
| use-board-004 | frame-subscription, frame-no-second-connection | This logic is active and the first fetch is done; every registered frame subscriber is invoked once | The network has been called exactly 2 times; no separate streaming connection is created |
| use-board-005 | verdict-stale, stale-threshold, error-independent-of-board | Server returns 200 with `generatedAt` = now − 180,000 ms − 5,000 ms | `board` null; `reason` `"stale"`; `error` null |
| use-board-006 | verdict-frozen, frozen-threshold, frozen-server-clock | Server returns fresh `generatedAt`, `dataAsOfMs` = now − the default data-staleness window − 5,000 ms, green indicator, no problems | `board` null; `reason` `"frozen"` (not `"stale"`); `error` null |
| use-board-007 | verdict-no-data | Server returns fresh `generatedAt`, `dataAsOfMs: null` | `board` null; `reason` `"no-data"` |
| use-board-008 | verdict-current | Server returns fresh `generatedAt`, `dataAsOfMs` = now − 1,000 ms, `indicator: "operational"` | `reason` null; `board.indicator` `"operational"` |
| use-board-009 | verdict-loading, single-loading-signal | The network is stubbed with a request that never resolves; read result immediately after this logic becomes active | `board` null; `reason` `"loading"`; the result carries no separate loading flag |
| use-board-010 | fetch-http-error, verdict-unavailable, error-field, retry-once | The network always returns status 500; wait for the read to settle | The network is called 2 times (initial + one retry); `board` null; `reason` `"unavailable"`; `error.message` is `board fetch failed: 500` |
| use-board-011 | fetch-request, query-key | This logic becomes active | The first network call has URL `/api/board` and headers `{ accept: "application/json" }` |
| use-board-012 | stale-unparseable-clock | Server returns `generatedAt: "not-a-date"`, `dataAsOfMs` = now | `board` null; `reason` `"stale"` |
| use-board-013 | stale-over-frozen | Server returns `generatedAt` = now − 200,000 ms, `dataAsOfMs` = now − 900,000 ms | `reason` `"stale"` |
| use-board-014 | frozen-threshold | Not stale; `probeIntervalMs` 3,600,000; lag between `generatedAt` and `dataAsOfMs` = 30,000,000 ms | `reason` null (window is 36,000,000 ms); with lag 36,000,001 ms, `reason` `"frozen"` |
| use-board-015 | fetch-parse-error, verdict-unavailable | The network returns status 200 with body `not json` on every call | `board` null; `reason` `"unavailable"`; `error` is a parse error |
| use-board-016 | frame-unsubscribe | This logic becomes active, then is torn down | the mocked frame subscriber set no longer contains its callback |
| use-board-017 | retained-data-ages-out | First read returns a fresh board; every later read returns 500; advance the clock past `generatedAt` + 180,000 ms + 30,000 ms | `board` null; `reason` `"stale"`; `error` non-null |

Vectors 001–008, 009–011 and 015–017 are derived from the implementation's test suite; 012–014 are derived from the staleness component's own rules (see Platform Notes).

