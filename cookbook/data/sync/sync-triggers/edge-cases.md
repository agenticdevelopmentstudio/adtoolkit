
- **Zero or negative periodic interval**: the sleep returns immediately and the task yields `.periodic` in a tight loop into the unbounded buffer; see periodic-interval-precondition (MUST, as the source behaves).
- **Very large periodic interval**: the first tick is delayed by the full interval; `stop()` still cancels the sleep at once, so teardown is not delayed (MUST).
- **Stop before first tick**: calling `stop()` during the first sleep yields nothing and ends iteration (MUST).
- **Slow or absent consumer**: every source buffers without limit, so ticks accumulate in memory until consumed; the engine coalesces kicks that arrive during a running cycle, but the source itself never drops (MUST).
- **Released periodic source**: `deinit` calls `stop()`, so the consumer's iteration ends (MUST).
- **Released connectivity source without stop**: no explicit cancel or finish runs; teardown is left to deallocation of the monitor and continuation (MUST, as the source behaves).
- **Device already online at construction**: the first update is satisfied and yields nothing; a host wanting an immediate sync fires one through a manual source or calls the engine directly (MUST).
- **Flapping network**: every not-satisfied → satisfied transition yields one `.connectivityRestored`, with no debounce or rate limit; the engine's coalescing absorbs bursts (MUST).
- **Connectivity stop before any path update**: iteration ends with no element (MUST).
- **Concurrent queue passed to connectivity source**: the previous-status flag is unprotected; see connectivity-queue-precondition.
- **Concurrent `fire(_:)` calls**: each call yields once; the continuation serialises them, with no guaranteed order between calls from different tasks (MUST).
- **Empty `hostSpecific` payload**: `fire(.hostSpecific(""))` is yielded unchanged (MUST).
- **Multiple consumers of one stream**: not supported; `AsyncStream` is single-consumer and concurrent `next()` calls from two tasks are a runtime error (MUST NOT).
- **Engine stopped, source still running**: the source keeps producing into its buffer until the host stops or releases it (MUST).
- **Errors and offline state**: no source performs I/O that can fail; the connectivity source reports offline only by not yielding, and the periodic source keeps ticking while offline (MUST).

