
### Lifecycle and concurrency

- **single-owner-state**: The engine MUST confine every mutable field (running flag, pending reason, auth-paused flag, host-paused flag, cycle waiters, consecutive-failure count, consecutive-resync count, trigger tasks, retry task) to itself, accessed only through its own operations.
- **concurrency-safe-values**: Every wire type, JSON value, event, kick reason, local mutation and the engine's configuration MUST be safe to pass across concurrent contexts, and the store, transport and trigger-source contracts MUST require the same of their conforming implementations.
- **single-cycle**: The engine MUST run at most one cycle at a time; a kick that arrives while a cycle is running MUST NOT start a second concurrent cycle.
- **events-stream**: `events` MUST be an ordered event stream created with a buffering policy of the newest 256 events; when a subscriber falls more than 256 events behind, the oldest undelivered events MUST be dropped.
- **attach-trigger**: Attaching a trigger source MUST start a background process that calls `kick` once for every value the trigger's kick stream yields, in stream order, and MUST hold the engine weakly, so an attached trigger never keeps the engine alive.
- **stop-cancels**: `stop` MUST cancel every attached trigger task, cancel any pending retry task, and finish the `events` stream.
- **stop-in-flight**: `stop` MUST NOT wait for or cancel a cycle already in flight; that cycle continues to call the store and transport until it ends.
- **stop-during-cycle**: `stop` MUST NOT be relied on to prevent later work: it sets no stopped flag, so a cycle suspended mid-operation when `stop` runs can still reach the retry scheduler on failure and arm a new retry that later calls `kick` with reason `periodic` after the host stopped the engine, with every event it yields discarded by the finished stream. A host SHOULD `pause` before `stop`.

### Entry points and coalescing

- **kick-paused**: `kick` MUST return without effect while host-paused is true.
- **kick-coalesce**: `kick` called while a cycle is running MUST record the reason as the pending reason only when none is already recorded, and MUST return without waiting for the cycle.
- **kick-start**: `kick` called while idle and unpaused MUST run a cycle through `syncNow` and return when that call returns.
- **pending-first-wins**: When several kicks coalesce into one running cycle, only the first recorded reason MUST be kept; later reasons are discarded.
- **syncnow-paused**: `syncNow` MUST return immediately, without a cycle, while host-paused is true.
- **syncnow-auth-gate**: While auth-paused is true, `syncNow` MUST return immediately unless the reason is `manual` or `hostSpecific`; for those two it MUST clear the auth-paused state and proceed.
- **syncnow-join**: `syncNow` called while a cycle is running MUST record its reason as the pending reason (first wins) and MUST suspend until the running cycle finishes; it MUST NOT wait for the follow-up cycle its reason may trigger.
- **follow-up-cycle**: When a cycle ends with host-paused false and a pending reason recorded, the engine MUST clear the pending reason and immediately run exactly one more cycle with that reason.
- **pause-drops-pending**: When a cycle ends with host-paused true, the engine MUST discard any pending reason rather than run it after `resume`.
- **pause-wait**: `pause` MUST set the host-paused state; if a cycle is running it MUST suspend until that cycle finishes, and if none is running it MUST return immediately.
- **resume-no-sync**: `resume` MUST clear the host-paused state and MUST NOT start a cycle itself.
- **waiters-resumed**: At the end of every cycle, every caller waiting on `pause` or a joining `syncNow` MUST be resumed exactly once, before any follow-up cycle starts.

### Cycle outcome

- **cycle-order**: A cycle MUST emit a `started` event carrying the reason, then run the pull loop to completion, then the push loop to completion; the push loop MUST NOT start if the pull loop raised an error.
- **cycle-success**: A cycle whose pull and push loops both complete MUST reset the consecutive-failure and consecutive-resync counts to 0 and emit an `idle` event.
- **unauthorized-pause**: An unauthorized transport error raised anywhere in the cycle MUST set the auth-paused state, emit an `authRequired` event, and MUST NOT emit a `failed` event or schedule a retry.
- **resync-required**: A resync-required transport error raised in the cycle MUST run the resync procedure (see **resync-procedure**) instead of emitting a `failed` event.
- **generic-failure**: Any other error MUST increment the consecutive-failure count, emit a `failed` event carrying a description of the error, and schedule a retry; no outbox op may be removed as a result.
- **engine-error-text**: The engine's internal errors MUST describe themselves as "push made no progress", "pull made no progress" and "manifest unstable" for a push-made-no-progress, pull-made-no-progress and manifest-unstable error respectively, so those strings are the `failed` event's payload.
- **invalid-response-generic**: A generic transport error or an invalid-response error (carrying a status code) MUST take the generic-failure path; the engine gives them no special handling.

### Backoff

- **backoff-delay**: A scheduled retry MUST wait `min(baseBackoff * 2^(min(consecutiveFailures, 16) - 1), maxBackoff)` seconds, then call `kick` with reason `periodic`.
- **backoff-single-timer**: Scheduling a retry MUST cancel any retry task already pending, so at most one retry timer exists.
- **backoff-cancelled**: A retry task cancelled before its delay elapses MUST NOT kick.

### Pull loop

- **registrations-snapshot**: The pull loop MUST read `registrations` once at cycle start and keep that local snapshot current as reconciliation purges and preparation registers, rather than re-reading it per page.
- **pull-request**: Each page MUST call the transport's pull operation with the store's current `cursor` and `pullLimit`.
- **effective-set**: The effective resource set MUST equal the page's manifest when `hostResources` is not set, and the manifest filtered to resources whose names appear in `hostResources` otherwise; the manifest's `schemaVersion` is the one kept.
- **reconcile-before-prepare**: Reconciliation MUST run on every page, before the page's `prepare` and `apply`.
- **prepare-when-changed**: The engine MUST call `prepare` with the effective set only when the snapshot does not already hold every effective resource at the identical `schemaVersion`, and MUST then record those versions in the snapshot.
- **change-filter**: When `hostResources` is set, only changes whose resource is in the effective set MUST be applied; when it is not set, every change in the page MUST be applied unfiltered.
- **apply-advances**: The page's applicable changes MUST be passed to `apply`, together with the response's cursor, in a single call.
- **pulled-batch-event**: After each successful apply the engine MUST emit a `pulledBatch` event carrying the applicable-change count and the new cursor, including for an empty page.
- **pull-continues**: The pull loop MUST request another page while the last response's `hasMore` is true, and stop when it is false.
- **pull-no-progress**: A response with no changes, `hasMore` true, and a cursor equal to the one requested MUST count as no progress; 2 consecutive no-progress responses MUST raise a pull-made-no-progress error, and any other response MUST reset the count to 0.

### Manifest reconciliation

- **reconcile-plan**: Reconciliation planning MUST be a pure computation over the registered and effective resource sets, returning three name lists, each sorted ascending: `disabled` (registered, absent from the effective set), `bumped` (registered at a `schemaVersion` different from the manifest's, higher or lower), and `appeared` (effective, not registered, and not in `bumped`).
- **unregistered-event**: When `hostResources` is set, the engine MUST emit an `unregisteredManifestResources` event carrying the sorted manifest names outside the effective set, only when that list is non-empty and differs from the list last emitted in the same cycle.
- **disable-purge**: A non-empty `disabled` list MUST be passed to `purgeResources`, removed from the snapshot, and reported as a `resourcesDisabled` event; disablement alone MUST NOT reset the cursor or resync.
- **manifest-complete**: The engine MUST treat each page's manifest as complete: a registered resource missing from any single page MUST be disabled on that page, with no floor for an empty or partial manifest.
- **bump-purge**: A non-empty `bumped` list MUST be passed to `purgeResources`, removed from the snapshot, and reported as a `resourcesSchemaBumped` event.
- **fresh-cursor-no-resync**: When the page was requested with no cursor, appearance and bump MUST NOT trigger a resync.
- **reconcile-resync**: When the page was requested with a cursor and `appeared` or `bumped` is non-empty, the engine MUST call `resetForResync`, emit a `resourcesEnabled` event when `appeared` is non-empty, emit a `resyncPerformed` event, skip the page's changes, and restart the pull from the (now cleared) stored cursor.
- **reconcile-bound**: More than 3 reconcile-triggered resets in one cycle MUST raise a manifest-unstable error.

### Push loop

- **push-batch**: The push loop MUST fetch up to `pushBatchSize` ops with `pendingOps` and return when none remain.
- **push-request**: Each batch MUST be sent as one push request carrying the configured `deviceId` and the batch of ops.
- **applied-result**: An applied result MUST be counted as applied and forwarded unchanged to `complete`, including its new version.
- **rejected-result**: A rejected result MUST be counted as rejected and forwarded unchanged to `complete`.
- **conflict-unmatched**: A conflict result whose `opId` matches no op in the batch MUST be counted as a conflict and forwarded unchanged, with nothing adopted.
- **conflict-no-current**: A conflict result with no current row MUST be counted as rejected and forwarded as rejected with its original reason, with nothing adopted.
- **conflict-unadoptable**: A conflict result whose current row's `sync_version` cannot be adopted MUST be counted as rejected and forwarded as rejected with its original reason, with nothing adopted.
- **adopted-version**: A missing `sync_version` MUST adopt as "0"; a numeric value MUST adopt as its decimal integer text only when it converts exactly to a 64-bit integer; a string value MUST adopt verbatim only when it parses as an integer; every other JSON type MUST be unadoptable.
- **adopted-version-sign**: Version adoption MUST accept whatever the integer parser accepts, including a leading `+` or `-` and negative numbers, although a change's `syncVersion` is documented as digits only: a value such as "-5" or "+5" passes through to `apply`, which could raise an error and re-push the op every cycle (the wedge the adoption fix set out to remove).
- **conflict-adopt**: An adoptable conflict MUST produce one change record for the op's resource and row id at the adopted version, emit a `conflictResolved` event, and forward the result unchanged.
- **delete-wins**: The adopted change MUST be a delete with no data when the current row's `deleted_at` is present and not null, and an upsert otherwise; a missing `deleted_at` key counts as not deleted.
- **strip-bookkeeping**: An adopted upsert MUST carry the current row with the `sync_version` and `sync_stamped_at` keys removed.
- **adopt-before-complete**: All of a batch's adoptions MUST be applied in one `apply` call with no cursor advance, skipped when there are none, before `complete` is called with every result.
- **pushed-event**: After `complete`, the engine MUST emit a `pushed` event with the batch's applied, conflict and rejected counts.
- **push-no-progress**: After each batch, when every attempted `opId` is still returned by `pendingOps` at the configured `pushBatchSize`, the engine MUST raise a push-made-no-progress error; this covers an empty results list for a non-empty batch.

### Resync (HTTP 410)

- **resync-procedure**: The resync procedure MUST call `resetForResync`, emit a `resyncPerformed` event, run the pull loop, then the push loop; on success it MUST reset both failure counters and emit an `idle` event.
- **resync-preserves-outbox**: Resync MUST replay the preserved outbox under its original `opId`s; the engine MUST NOT re-stage or re-mint ops.
- **resync-unauthorized**: An unauthorized error during resync MUST set the auth-paused state and emit an `authRequired` event, with no `failed` event and no retry.
- **resync-nested-once**: A resync-required error during resync MUST increment the consecutive-resync count; while it is 1 or less the resync MUST be retried immediately, and above 1 the engine MUST increment the consecutive-failure count, emit a `failed` event with message "repeated resync_required from server; backing off", and schedule a retry.
- **resync-counter-persists**: The consecutive-resync count MUST persist across cycles and reset only on a fully successful cycle or resync.
- **resync-other-failure**: Any other error during resync MUST take the generic-failure path.

### Store and transport contract (injected)

- **store-atomic**: The store contract MUST make `stage` and `apply` atomic with the outbox mutations they imply.
- **store-apply-nil-cursor**: `apply` with no cursor MUST apply without advancing the cursor.
- **store-stage-registered**: `stage` MUST raise an unknownResource error for a resource never passed to `prepare`; hosts MUST `prepare` before staging.
- **store-prepare-idempotent**: `prepare` MUST be idempotent, upserting schema versions.
- **store-complete-terminal**: `complete` MUST resolve ops by `opId`, and a rejected op MUST never be retried under the same `opId`; a retry MUST go through a fresh `stage`.
- **store-reset**: `resetForResync` MUST clear mirror rows and the cursor, preserve the outbox, and never delete the database file.
- **store-purge**: `purgeResources` MUST delete the resources' mirror rows, quarantine their pending and in-flight ops, remove their registrations, and leave the cursor untouched.
- **transport-errors**: The transport contract MUST map HTTP 401 to an unauthorized error and HTTP 410 to a resync-required error; the engine owns no credentials.

### Supporting value types

- **jsonvalue-decode-order**: The JSON value type MUST decode null, then boolean, then floating-point number, then string, then array, then object, and raise a decoding error ("not JSON") when none match.
- **jsonvalue-number-lossy**: Every JSON number MUST decode to a floating-point number; integers beyond 2^53 lose precision by design of this projection.
- **jsonvalue-accessors**: Looking up a key MUST return nothing on a non-object value, reading it as a string MUST return nothing on a non-string value, and a null check MUST be true only for the null value.
- **uuidv7-format**: The id generator MUST return a 36-character lowercase hyphenated UUID with version nibble 7 and the RFC 4122 variant bits.
- **uuidv7-monotonic**: Ids minted by one process MUST sort strictly increasing: a new millisecond resets a 12-bit counter to a random value in 0...0x7FF, the same or an earlier millisecond increments it, and a counter at 0xFFF borrows the next millisecond and restarts at 0; all of this happens under one process-wide serialization point.
- **reached-backend**: Each event's reachedBackend flag MUST be true for `pulledBatch`, `idle` and `authRequired` and false for every other event.
- **catalog-shape**: The generated resource catalog MUST list 97 unique resources, all at schema version 1, and its pull-only subset MUST be a 44-name subset of them; the catalog is generated and is client knowledge only — the server manifest gates what syncs.
- **engine-ignores-watermark**: The engine MUST NOT read the push response's watermark field.

