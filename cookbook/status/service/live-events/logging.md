
Subsystem: `status-server` | Category: `live-events`

| Event | Level | Message |
|-------|-------|---------|
| A subscriber callback throws during `publishSnapshot` | error | `[live-events] subscriber threw:` followed by the caught error |
| `buildLiveSnapshot` rejects inside a scheduled `emitLiveUpdate` build | error | `[live-events] emit build failed:` followed by the caught error |

