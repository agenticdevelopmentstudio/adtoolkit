
### Constants

- **board-poll-interval**: `BOARD_POLL_INTERVAL_MS` MUST equal 60 000 ms. It is the board's own poll cadence. The module owns it so that the threshold derivation does not reach into the hook file, and `useBoard` imports it as its `refetchInterval`.
- **board-stale-threshold**: `BOARD_STALE_MS` MUST equal `3 * BOARD_POLL_INTERVAL_MS`, which is 180 000 ms (three missed poll cycles).
- **data-stale-cycles**: `BOARD_DATA_STALE_CYCLES` MUST equal 2. The doc comment requires it to be at least 2, because a window equal to one write cadence is crossed at the tail of every cycle.

### isBoardStale

- **read-stale-signature**: `isBoardStale` MUST take `generatedAt: string` (the board's own read timestamp) and `nowMs: number` (epoch milliseconds from the caller's clock), and MUST return a `boolean`.
- **read-stale-age**: `isBoardStale` MUST compute age as `nowMs - Date.parse(generatedAt)`.
- **read-stale-strict-threshold**: `isBoardStale` MUST return `true` when the age is strictly greater than `BOARD_STALE_MS`.
- **read-stale-at-threshold**: `isBoardStale` MUST return `false` when the age is exactly `BOARD_STALE_MS`.
- **read-stale-fail-closed**: `isBoardStale` MUST return `true` when the age is not a finite number, which happens when `generatedAt` is unparseable. The doc comment says an unparseable clock means "we cannot tell", and an absence of a judgeable claim must never render as health.
- **read-stale-future-age**: `isBoardStale` MUST return `false` for a negative age, when `generatedAt` is ahead of `nowMs`. The function applies no lower bound.
- **read-stale-client-clock**: The caller MUST supply `nowMs` from the client clock (`useNow()` at the sole call site), not from another server timestamp. The doc comment says the client clock is the one timestamp that keeps moving when every server-side feed has died.
- **read-stale-no-skew-correction**: `isBoardStale` MUST NOT attempt to detect or correct client clock skew. The doc comment deliberately accepts that a client clock running more than `BOARD_STALE_MS` fast false-trips a healthy board to stale, and that one running more than `BOARD_STALE_MS` slow masks a frozen board.
- **read-stale-precondition**: `isBoardStale` only judges a board that has arrived. Per its doc comment, callers MUST check `board === null` (no board at all) first, as the separate and stronger signal.

### boardDataStaleMs

- **data-window-signature**: `boardDataStaleMs` MUST take an optional `probeIntervalMs?: number | null` and MUST return a number of milliseconds.
- **data-window-formula**: `boardDataStaleMs` MUST return `snapshotStaleMs(probeIntervalMs) * BOARD_DATA_STALE_CYCLES`. `snapshotStaleMs` is `Math.max((probeIntervalMs ?? 0) * 5, SNAPSHOT_STALE_FLOOR_MS)`, and `SNAPSHOT_STALE_FLOOR_MS` is 300 000 ms.
- **data-window-unknown-cadence**: `boardDataStaleMs` MUST return 600 000 ms (the floor times two) when `probeIntervalMs` is `undefined`, `null` or `0`. An unknown cadence can only delay the verdict, never false-trip it.
- **data-window-exceeds-cadence**: For every positive `probeIntervalMs`, `boardDataStaleMs` MUST return a value strictly greater than the backend's platform-sample cadence `max(300_000, probeIntervalMs * 5)`.

### boardDataFreshness

- **freshness-type**: `BoardDataFreshness` MUST be the string union `"current" | "frozen" | "no-data"`.
- **freshness-signature**: `boardDataFreshness` MUST take `dataAsOfMs: number | null`, `generatedAt: string` and an optional `probeIntervalMs?: number | null`, and MUST return a `BoardDataFreshness`.
- **freshness-no-data**: `boardDataFreshness` MUST return `"no-data"` whenever `dataAsOfMs` is `null`, before it parses `generatedAt` or reads `probeIntervalMs`. The doc comment says "no-data" means the board rests on no observation at all. That is never health, but it is not evidence of a fault either.
- **freshness-lag**: `boardDataFreshness` MUST compute lag as `Date.parse(generatedAt) - dataAsOfMs`, which compares a server clock against a server clock.
- **freshness-fail-closed**: `boardDataFreshness` MUST return `"frozen"` when the lag is not finite, for example when `generatedAt` is unparseable. This matches `isBoardStale`.
- **freshness-frozen**: `boardDataFreshness` MUST return `"frozen"` when the lag is strictly greater than `boardDataStaleMs(probeIntervalMs)`.
- **freshness-current**: `boardDataFreshness` MUST return `"current"` when the lag is finite and less than or equal to `boardDataStaleMs(probeIntervalMs)`. That range includes a negative lag, when the data clock is slightly ahead of `generatedAt`.
- **freshness-skew-immune**: `boardDataFreshness` MUST NOT read the client clock. Its verdict depends only on its arguments.

### Purity and concurrency

- **pure-functions**: Every exported function MUST be pure and synchronous. They MUST NOT perform I/O, log, throw on any input of the declared types, or mutate state.
- **single-threaded**: The module holds no state and runs on the single JavaScript thread, so concurrent calls cannot interleave and it needs no ordering rule.

