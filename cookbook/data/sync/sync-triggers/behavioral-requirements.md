
### Shared contract

- **trigger-protocol**: A trigger source MUST expose a read-only `kicks` stream of `SyncKickReason` values; this is the only member `SyncTriggerSource` requires.
- **trigger-sendable**: Every trigger source type MUST be safe to share across concurrency domains; each source relies on its stream continuation (and, for connectivity, the monitor's serial queue) for thread safety.
- **kick-reason-cases**: `SyncKickReason` MUST have exactly four cases: `periodic`, `connectivityRestored`, `manual`, and `hostSpecific` carrying one `String` payload.
- **kick-reason-equality**: Two `SyncKickReason` values MUST compare equal only when they are the same case and, for `hostSpecific`, carry equal strings.
- **stream-created-at-init**: Each source MUST create its `kicks` stream and its continuation in its initializer, so the stream exists before any consumer subscribes.
- **unbounded-buffer**: Each source's stream MUST buffer every yielded reason until it is consumed; the streams are created with the default (unbounded) buffering policy, so no kick is dropped for a slow consumer.
- **single-consumer**: Each source's `kicks` stream MUST be consumed by a single iterating task; the stream is a unicast `AsyncStream` and is not a broadcast channel.
- **finish-ends-iteration**: After a source's continuation is finished, a consumer's pending or next iteration MUST return end-of-sequence once any already-buffered reasons are drained.
- **engine-stop-does-not-stop-source**: Stopping the engine MUST NOT stop an attached source; `SyncEngine.stop()` cancels only its own consuming tasks, so the host owns calling `stop()` on periodic and connectivity sources.

### PeriodicTriggerSource

- **periodic-init**: `PeriodicTriggerSource(interval:)` MUST start ticking immediately on construction, with no separate start call.
- **periodic-reason**: Every element a periodic source yields MUST be `.periodic`.
- **periodic-first-tick-delay**: The first `.periodic` MUST be yielded after one full `interval` has elapsed; there is no tick at construction time.
- **periodic-fixed-delay**: Each subsequent tick MUST be scheduled `interval` seconds after the previous yield (fixed delay, not fixed rate), so any scheduling lateness accumulates rather than being corrected.
- **periodic-stop-cancels**: `stop()` MUST cancel the ticking task so no further `.periodic` is yielded.
- **periodic-stop-finishes**: `stop()` MUST finish the stream so a consumer's iteration ends.
- **periodic-cancel-check**: After waking from each sleep, the ticking task MUST check for cancellation and exit without yielding if cancelled.
- **periodic-sleep-error**: A thrown error from the interval sleep MUST be discarded; the only error the sleep can throw is cancellation, which the post-sleep cancellation check then acts on.
- **periodic-deinit-stops**: Releasing the last strong reference to a periodic source MUST perform the same teardown as `stop()`; `deinit` calls `stop()`.
- **periodic-no-self-capture**: The ticking task MUST NOT retain the source instance; it captures only the local continuation, so the source can be deallocated while the task is running.
- **periodic-stop-idempotent**: Calling `stop()` more than once, including the implicit call from `deinit` after an explicit one, MUST have no additional effect.
- **periodic-interval-precondition**: A positive `interval` is a caller precondition. `init(interval:)` accepts any `TimeInterval` with no check; a zero or negative interval makes the sleep return at once, so the task yields `.periodic` in a tight loop into the unbounded buffer.

### ConnectivityTriggerSource

- **connectivity-init**: `ConnectivityTriggerSource(queue:)` MUST start monitoring the network path immediately on construction, delivering path updates on the supplied queue.
- **connectivity-default-queue**: When no queue is passed, the source MUST use a new serial dispatch queue labelled `ConnectivityTriggerSource`.
- **connectivity-reason**: Every element a connectivity source yields MUST be `.connectivityRestored`.
- **connectivity-transition-only**: The source MUST yield `.connectivityRestored` only when a path update reports satisfied and the immediately preceding update reported not satisfied.
- **connectivity-no-initial-kick**: The first path update after construction MUST NOT yield, whatever its status; with no previous observation there is no transition.
- **connectivity-unsatisfied-definition**: Any path status other than satisfied (including unsatisfied and requires-connection) MUST count as not satisfied.
- **connectivity-repeat-satisfied**: Consecutive satisfied updates MUST NOT yield more than once; only the first satisfied update after a not-satisfied one yields.
- **connectivity-stop-cancels**: `stop()` MUST cancel the path monitor so no further updates are processed.
- **connectivity-stop-finishes**: `stop()` MUST finish the stream so a consumer's iteration ends, even when called before any path update has arrived.
- **connectivity-no-deinit**: The connectivity source MUST NOT define a `deinit` teardown; unlike the periodic source, releasing it without calling `stop()` performs no explicit monitor cancellation or stream finish, so hosts call `stop()` themselves.
- **connectivity-queue-precondition**: A serial queue is a caller precondition. The previous-status flag is unsynchronized and is read and written by every path update on the supplied queue; the default, a serial execution queue labelled `ConnectivityTriggerSource`, is serial, so the flag is ordered. A caller that passes a concurrent queue leaves the flag unordered.

### ManualTriggerSource

- **manual-fire**: `fire(_:)` MUST yield exactly the reason passed, unchanged, including `.hostSpecific` payloads and non-manual cases such as `.periodic`.
- **manual-fire-before-subscribe**: A reason fired before any consumer iterates MUST be buffered and delivered to the first `next()`.
- **manual-fire-any-thread**: `fire(_:)` MUST be callable from any thread or task without external synchronisation.
- **manual-no-stop**: The manual source MUST NOT provide a `stop()`; it holds no task or OS handle, and its stream is released with the instance.
- **manual-no-validation**: `fire(_:)` MUST accept any `SyncKickReason`, including `.hostSpecific("")`, without validation; interpretation of the reason belongs to the engine.

