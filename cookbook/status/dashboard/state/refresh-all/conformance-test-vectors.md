
There is no dedicated test file for this concept. The vectors below are derived from the source and assume a shared cache context and a controllable timer.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| refresh-all-001 | interval-default, interval-start, no-immediate-refresh | Start using Refresh All with the default interval, with the refetch operation monitored; advance the timer by 59,999 ms, then by 1 ms more | Zero calls after 59,999 ms; exactly one call at 60,000 ms |
| refresh-all-002 | interval-start | Start using Refresh All with a 1,000 ms interval; advance the timer by 3,000 ms | The refetch operation is triggered exactly 3 times |
| refresh-all-003 | live-excluded, others-included | Cache holds enabled, fetched entries `["live"]`, `["live", "x"]`, `["uptime"]` and `["integrations"]`; call `refreshAll` | The uptime and integrations entries' read functions each run once; neither live entry's read function runs |
| refresh-all-004 | live-prefix-only | Cache holds enabled entries `["live-history"]` and `["history", "live"]`; call `refreshAll` | Both entries' read functions run once |
| refresh-all-005 | disabled-excluded | Cache holds `["config-status"]` whose only observer is disabled; call `refreshAll` | Its read function does not run |
| refresh-all-006 | disabled-means-no-enabled-observer | `["configure-data"]` has one disabled observer and one enabled observer; call `refreshAll` | Its read function runs once |
| refresh-all-007 | fire-and-forget, errors-land-on-queries | The `["uptime"]` entry's read function rejects with an error message `"boom"`; call `refreshAll` | `refreshAll` returns immediately with nothing; after settling, the uptime entry is in an error state with message `"boom"`; no unhandled failure |
| refresh-all-008 | independent-completion | `["a"]` resolves `1`, `["b"]` rejects; call `refreshAll` | Entry `["a"]`'s data becomes `1` even though `["b"]` ends in an error state |
| refresh-all-009 | interval-cleanup | Start using Refresh All with a 1,000 ms interval, stop using it, advance the timer by 5,000 ms | The refetch operation is triggered zero times after that |
| refresh-all-010 | interval-restart-on-change | Start with a 1,000 ms interval; advance 500 ms; change the interval to 2,000 ms; advance 1,999 ms, then 1 ms more | No call before the change and none during the 1,999 ms; exactly one call at 2,000 ms after the change |
| refresh-all-011 | refresh-all-stable, return-object-fresh | Use Refresh All twice with the same cache context | The `refreshAll` reference is the same each time; the wrapper objects are different references |
| refresh-all-012 | refetch-call | Call `refreshAll` once | The refetch operation is triggered once with one argument, an object whose only key is the filter |
| refresh-all-013 | one-timer-per-mount | Use Refresh All twice, each with a 1,000 ms interval, sharing one cache context; advance 1,000 ms | The refetch operation is triggered twice |
| refresh-all-014 | client-only | Load Refresh All in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

