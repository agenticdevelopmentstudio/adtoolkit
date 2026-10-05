
### Pub/Sub Core

- **subscription-registration**: `subscribeLive` MUST add the given callback
  to the module-scope subscriber set and MUST return a function that, when
  called, removes exactly that callback from the set.
- **unsubscribe-idempotent**: Calling the function `subscribeLive` returns
  more than once MUST have no further effect after the first call, because
  removing an already-absent entry from a `Set` is a no-op.
- **duplicate-callback-reference**: Subscribing the identical callback
  function reference a second time MUST NOT increase `liveSubscriberCount`,
  because a `Set` stores each distinct reference once; either caller's
  returned unsubscribe function then removes the one shared entry.
- **publish-fanout-same-reference**: `publishSnapshot` MUST invoke every
  currently registered subscriber callback with the exact same `LiveSnapshot`
  object reference it was given, never a copy, so that N registered
  subscribers cost one built object, not N.
- **publish-subscriber-isolation**: `publishSnapshot` MUST catch any error a
  subscriber callback throws, log it via `console.error`, and continue
  delivering to the remaining subscribers; a throwing subscriber MUST NOT
  stop delivery to any other subscriber and MUST NOT cause `publishSnapshot`
  itself to throw.
- **publish-updates-cache-unconditionally**: `publishSnapshot` MUST record
  the given snapshot and the current wall-clock time as the most recently
  published snapshot regardless of whether any subscriber is currently
  registered.
- **subscriber-count**: `liveSubscriberCount` MUST return the exact current
  size of the subscriber set.

### Recency Cache

- **recent-snapshot-null-before-publish**: `recentSnapshot` MUST return
  `null` when no snapshot has ever been published, or after `resetLiveEvents`
  has run.
- **recent-snapshot-freshness-window**: `recentSnapshot(maxAgeMs)` MUST
  return the most recently published snapshot when the elapsed time since it
  was published is less than or equal to `maxAgeMs`, and MUST return `null`
  otherwise.

### Debounced Emit

- **emit-skips-when-idle**: `emitLiveUpdate` MUST return immediately, without
  scheduling a build and without calling any `Storage` method, when zero
  subscribers are registered.
- **emit-coalesces-concurrent-calls**: `emitLiveUpdate` MUST schedule at most
  one pending build at a time; a call made while a build is already scheduled
  MUST return immediately without rescheduling or extending the existing
  delay.
- **emit-fixed-coalesce-window**: The scheduled build MUST run exactly 150
  milliseconds (`COALESCE_MS`) after the first `emitLiveUpdate` call of a
  burst, never after the last call of the burst, because later calls in the
  burst are absorbed by `emit-coalesces-concurrent-calls` without touching
  the timer.
- **emit-build-and-publish**: The scheduled build MUST call
  `buildLiveSnapshot` with the `storage` and `config` values captured from
  the call that armed the timer, and MUST pass its resolved result to
  `publishSnapshot` on success.
- **emit-build-failure-logged-not-thrown**: When the build's promise rejects,
  the scheduled build MUST log the error via `console.error` and MUST NOT
  throw into, or otherwise notify, the code that originally called
  `emitLiveUpdate`.
- **emit-no-retry**: `emitLiveUpdate` MUST NOT itself retry a failed build;
  the next call to `emitLiveUpdate`, from the next cycle, webhook, or the
  client's own polling fallback, is the only path to a fresh attempt.

### Test Utility

- **reset-clears-subscribers-and-cache**: `resetLiveEvents` MUST clear the
  subscriber set and the cached last-published snapshot.
- **reset-cancels-armed-timer**: `resetLiveEvents` MUST cancel a debounce
  timer that `emitLiveUpdate` has armed but that has not yet fired, so its
  scheduled build never runs.
- **in-flight-build-cancellation**: Resetting live events MUST cancel a pending debounced build. Once the debounce timer has fired, the pending marker is cleared and the build is in flight, and reset has nothing left to cancel it with: a build that started just before a reset can still resolve afterward and publish, repopulating the cache and delivering to whichever subscribers are registered at that later moment.

### Module Scope & Concurrency

- **single-threaded-mutation**: Every read and write of the module-scope
  subscriber set, cached snapshot, and pending-timer handle executes
  synchronously within Node's single-threaded event loop, so two
  `subscribeLive`/`publishSnapshot`/`emitLiveUpdate` calls MUST NOT interleave
  mid-mutation; this is a property of the JavaScript execution model, not a
  lock this file implements, and it does not extend across the `await`
  boundary inside the scheduled build (see the open question on
  in-flight-build-cancellation above).
- **process-wide-singleton**: All pub/sub state MUST be shared by every
  caller within one running process (module scope, not per-request or
  per-`Storage`-instance). Per the module's own doc comment this is exact on
  the single long-running container this package targets, and best-effort
  per instance on a hypothetical multi-instance deployment, where a client
  connected to one instance never observes a push raised on another; the
  client's polling fallback re-reads the database regardless, so a missed
  push only adds latency, never loses data.
- **delivery-order-undefined-across-snapshots**: This module MUST NOT
  guarantee delivery order, deduplication, or monotonicity across multiple
  published snapshots; it delivers exactly what `publishSnapshot` is called
  with, in call order, and nothing more. Reconciling out-of-order, duplicate,
  or stale deliveries is the receiving client's responsibility, external to
  this file — the module's own doc comment sketches a `cycleAt`-based
  reconciliation on the client side, though the shared `LiveSnapshot` type
  (`monitor/live-types.ts`) names that field `lastCycleAt`, not `cycleAt`
  (see Design Decisions).

