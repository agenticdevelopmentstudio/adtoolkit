
All engine vectors use a configuration with deviceId "test-device", pullLimit 10, pushBatchSize 5, a scripted transport and an in-memory store.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sync-engine-001 | pull-request, pull-continues, apply-advances | Pages `a` (cursor c1, hasMore true) then `b` (cursor c2, hasMore false); `syncNow` with reason manual | Cursors sent are none then c1; stored cursor is c2; 2 mirror rows |
| sync-engine-002 | conflict-adopt, strip-bookkeeping, adopt-before-complete | Staged upsert r1; push returns a conflict with current row title "theirs", sync_version 9, sync_stamped_at, deleted_at empty | Outbox empty; mirror r1 title "theirs", syncVersion "9"; no sync_version/sync_stamped_at in its data |
| sync-engine-003 | delete-wins | Same as 002 but deleted_at is a timestamp | Outbox empty; r1 tombstoned with syncVersion "9" and empty data; live row count 0 |
| sync-engine-004 | conflict-no-current | Conflict result with no current row, reason "server_row_missing" | Outbox empty; op in quarantine; local title still "mine" |
| sync-engine-005 | conflict-unadoptable, adopted-version | Conflict result with sync_version being a non-finite number | Op quarantined; outbox empty; local row untouched |
| sync-engine-006 | conflict-unadoptable, pushed-event, cycle-success | Two ops: "bad" conflict with sync_version "not-a-number", "good" applied with new version "7" | Outbox empty; only "bad" quarantined; events contain an idle event, no failed event |
| sync-engine-007 | unauthorized-pause, syncnow-auth-gate | First pull raises an unauthorized error; then `syncNow` with reason periodic; then `syncNow` with reason manual | 1 pull after the periodic call; 2 pulls after the manual call |
| sync-engine-008 | resync-required, resync-preserves-outbox | Stored row "old" at cursor "stale", one staged op; pull raises a resync-required error, then returns row "fresh" | "fresh" present, "old" gone; the staged opId pushed exactly once; outbox empty |
| sync-engine-009 | resync-unauthorized | Pulls: a resync-required error, then an unauthorized error; then `syncNow` with reason periodic | 2 pulls total; events include a resyncPerformed event and an authRequired event, no failed event |
| sync-engine-010 | resync-nested-once, resync-counter-persists | Transport always raises a resync-required error; `syncNow` with reason manual, three times | Pull count 3, then 5, then 7; 3 failed events each containing "resync_required"; outbox still 1 op |
| sync-engine-011 | generic-failure | Push raises a generic transport error ("boom") | Outbox still holds 1 op |
| sync-engine-012 | backoff-delay, cycle-success | Pulls fail 3 times, succeed, fail once, succeed; baseBackoff 0.02 | Retries fire unaided; the post-success retry gap is under 3x the first retry gap; 4 failed events |
| sync-engine-013 | push-no-progress | Push result opId "bogus-op-id-not-in-outbox" applied | Outbox still 1 op; a failed event emitted |
| sync-engine-014 | push-no-progress, engine-error-text | Non-empty batch answered with an empty results list | No idle event; first failed event's payload is "push made no progress"; outbox 1 op |
| sync-engine-015 | rejected-result, store-complete-terminal | Push result rejected, reason "invalid_data"; then a second `syncNow` | Op quarantined; outbox empty; exactly 1 push request across both cycles |
| sync-engine-016 | pull-no-progress | Four pages all empty, cursor "stalled", hasMore true | Exactly 3 pulls; first failed event's payload is "pull made no progress" |
| sync-engine-017 | pause-wait | `pause` called while a gated pull is in flight | `pause` has not returned before release; returns after the cycle ends |
| sync-engine-018 | syncnow-join, follow-up-cycle | Two concurrent `syncNow` calls (manual, periodic) against a gated pull | Neither returns before release; both return after; exactly 2 pulls |
| sync-engine-019 | kick-paused, syncnow-paused, pause-drops-pending | `pause` while idle, then `kick` with reason periodic and `syncNow` with reason manual | 0 pulls |
| sync-engine-020 | resume-no-sync, kick-start | `pause`, `kick` with reason periodic, `resume`, `kick` with reason manual | Exactly 1 pull |
| sync-engine-021 | reconcile-resync, resync-preserves-outbox | Registered a.x at cursor c1; staged op on a.x; next manifest [a.x, b.y] | A resourcesEnabled event naming ["b.y"] and a resyncPerformed event; 3rd pull cursor cleared; staged op still pending; b.y has 1 row; cursor c3 |
| sync-engine-022 | disable-purge, manifest-complete | Registered a.x and b.y; staged op on b.y; next manifest [a.x] | A resourcesDisabled event naming ["b.y"], no resyncPerformed event; a.x keeps 1 row; b.y unregistered; op quarantined; cursor c2 |
| sync-engine-023 | bump-purge, reconcile-resync | a.x registered at 1; manifest reports 2 | A resourcesSchemaBumped event naming ["a.x"], a resyncPerformed event; 3rd pull cursor cleared; registration a.x = 2 |
| sync-engine-024 | bump-purge, reconcile-plan | a.x registered at 2; manifest reports 1 | Same bump path; registration a.x = 1; old row "1" gone, new row "2" present |
| sync-engine-025 | effective-set, change-filter, unregistered-event | hostResources [a.x]; manifest [a.x, b.y] with a change for each | An unregisteredManifestResources event naming ["b.y"]; a.x 1 row; registrations exactly a.x = 1 |
| sync-engine-026 | unregistered-event | hostResources [a.x]; 3 pages each with manifest [a.x, b.y] | 3 pulls; exactly one unregisteredManifestResources event naming ["b.y"] |
| sync-engine-027 | fresh-cursor-no-resync | Fresh store; manifest [a.x, b.y] | No resourcesEnabled event, no resyncPerformed event; one pulledBatch event |
| sync-engine-028 | reconcile-bound | Alternating pages manifest [a.x] then [a.x, b.y], four times | 8 pulls; failed event payloads exactly ["manifest unstable"] |
| sync-engine-029 | reconcile-plan | registered {a.x:1, b.y:1}, effective [a.x@1] | disabled ["b.y"], bumped [], appeared [] |
| sync-engine-030 | reconcile-plan | registered {a.x:1}, effective [a.x@2, b.y@1] | bumped ["a.x"], appeared ["b.y"], disjoint |
| sync-engine-031 | reconcile-plan | registered {a.x:1, b.y:1, c.z:3}, effective [] | disabled ["a.x", "b.y", "c.z"], others empty |
| sync-engine-032 | reached-backend | Each event kind | true for idle, pulledBatch, authRequired; false for the other nine |
| sync-engine-033 | uuidv7-format, uuidv7-monotonic | 1000 back-to-back id-generator calls | Strictly increasing, no duplicates, 36 characters, character 14 is "7" |
| sync-engine-034 | catalog-shape | The generated resource catalog | 97 unique names, 44 pull-only, all schemaVersion 1; "social.follows" pull-only, "content.contacts" not |
| sync-engine-035 | stop-during-cycle | A cycle is suspended mid-operation, the host calls `stop`, then the suspended cycle fails | A retry is still armed and later calls `kick` with reason `periodic`; its events are discarded by the finished stream |
| sync-engine-036 | adopted-version-sign | A conflict result whose current row carries `sync_version` as the string "-5" (and, separately, the number -5) | The signed value is accepted by the integer parser and adopted as "-5", passed to `apply` rather than the op being treated as unadoptable and rejected |

