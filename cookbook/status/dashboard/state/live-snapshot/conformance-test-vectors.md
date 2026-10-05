
Vectors 001–004 exercise the same-snapshot check directly. 005–020 assume a test double for the stream connection and the read transport, with the store reset between cases.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-live-snapshot-001 | same-snapshot-null | The same-snapshot check compares null against a snapshot with `generatedAt` `2026-06-30T00:00:00.000Z` | `false` |
| use-live-snapshot-002 | same-snapshot-identity | The same-snapshot check compares a snapshot against itself | `true` |
| use-live-snapshot-003 | same-snapshot-clock | Two distinct snapshot objects, both `generatedAt` `2026-06-30T00:00:00.000Z` | `true` |
| use-live-snapshot-004 | same-snapshot-clock | `generatedAt` `2026-06-30T00:00:00.000Z` vs `2026-06-30T00:01:00.000Z` | `false` |
| use-live-snapshot-005 | stream-path, stream-open-event, snapshot-frame, ingest-update | Use Live Snapshot; the stream opens, then delivers a snapshot with `generatedAt` `2030-01-01T00:00:00.000Z` and one service | Stream opened at `/api/live/stream`; `snapshot.generatedAt` equals that value; `snapshot.services` has length 1 |
| use-live-snapshot-006 | schedule-frame, result-next-poll-streaming | The stream opens, then delivers a schedule notification with `nextCheckAt` `"2030-06-01T00:00:00.000Z"` | `nextPollAt` equals the parsed timestamp of `2030-06-01T00:00:00.000Z` |
| use-live-snapshot-007 | check-start, check-post-sync, result-polling, check-resolve | Stream open, initial poll settled; call the manual check; then deliver a snapshot generated 5 s in the future | POST to `/api/live/check` sent synchronously; `polling` true; after the snapshot arrives, `polling` false |
| use-live-snapshot-008 | check-safety | With simulated time, call the manual check (reported as started); advance time 60,000 ms; then deliver a snapshot generated 90 s in the future | `polling` still true after 60 s; false after the snapshot arrives |
| use-live-snapshot-009 | check-started-no-refetch | No stream connection; poll settled; clear the record of requests; call the manual check (reported as started) | Zero GET requests to `/api/live` after the POST |
| use-live-snapshot-010 | stream-closed-error, stream-reopen | With simulated time; use Live Snapshot; report a terminal connection error; advance time 3,000 ms | 2 stream connections created in total |
| use-live-snapshot-011 | stream-transient-error | With simulated time; use Live Snapshot; report a transient connection error; advance time 10,000 ms | 1 stream connection in total |
| use-live-snapshot-012 | check-not-ran, check-not-ran-refetch | Stream not connected; call the manual check; the response reports `ran: false` | `polling` returns to false once the poll settles; one GET to `/api/live` issued after the POST |
| use-live-snapshot-013 | fetch-http-error, fetch-failure-sets-error, result-offline, result-disconnected, result-offline-detail | No stream; every GET to `/api/live` returns 503; the poll settles | `offline` true; `disconnected` true; `offlineDetail` is `"live 503"` |
| use-live-snapshot-014 | fetch-success-clears-error, live-error-sticky | After 013, the next GET to `/api/live` returns 200 with a snapshot | `offlineDetail` becomes null; `disconnected` becomes false; during the in-flight retry `disconnected` stayed true while `offline` was false |
| use-live-snapshot-015 | result-blind | Ingest a snapshot with `services: []` | `blind` true; with one service `blind` false; before any snapshot `blind` false |
| use-live-snapshot-016 | check-unrelated-push | Call the manual check (reported as started); deliver a snapshot generated one minute before the call | `snapshot` updated; `polling` stays true |
| use-live-snapshot-017 | snapshot-frame-malformed | The stream delivers a snapshot notification whose payload is not valid JSON | No error raised; `snapshot` unchanged; no frame subscriber called |
| use-live-snapshot-018 | ingest-once, frame-subscribe | Subscribe a counter to frame notifications; ingest the same snapshot once from the stream and once from the poll | Counter is 1 |
| use-live-snapshot-019 | stream-ref-count, stream-single, stream-release | Use Live Snapshot twice under one client; stop using it once; then stop using it again | 1 stream connection in total; still open after the first stop; closed after the second |
| use-live-snapshot-020 | client-estimate, result-next-poll-fallback | No stream; the poll succeeds with its last-success time at T | `nextPollAt` equals T + 60,000 |
| use-live-snapshot-021 | client-only | Load Live Snapshot in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

