
### Public shape

- **hook-signature**: Portfolio Indicator MUST take no arguments and MUST return a result with exactly the fields `pillKey` and `count`.
- **pill-key-type**: `pillKey` MUST be one of `"ok"`, `"warn"`, `"down"` or `"unknown"`.
- **count-type**: `count` MUST be a non-negative integer, the problem count backing the sign.
- **no-text-output**: Portfolio Indicator MUST NOT return headline text, labels or colours; formatting is the caller's responsibility.

### Inputs read

- **board-input**: Portfolio Indicator MUST read the board from the board state and MUST use only its board value; it MUST NOT read the board state's reason, error or refetch fields.
- **live-input**: Portfolio Indicator MUST read `snapshot`, `offline` and `blind` from Live Snapshot.
- **board-null-trusted**: Portfolio Indicator MUST treat a null board as "nothing current has come back" regardless of why the board state returned null (not yet loaded, fetch failed, stale, frozen or no data), and MUST NOT compute its own board-staleness term; the board state already folds a stale board into this same null value.

### Snapshot staleness

- **snapshot-stale-rule**: The live snapshot MUST be judged stale exactly when `snapshot` is non-null and the shared snapshot-freshness check (given the snapshot's `lastCycleAt`, `generatedAt` and `probeIntervalMs`) returns anything other than `"fresh"` (that is, `"stale"` or `"very-stale"`).
- **snapshot-null-not-stale**: A null `snapshot` (no live read yet) MUST NOT count as stale.
- **shared-staleness-rule**: The snapshot staleness verdict MUST come from one shared snapshot-freshness check, the same rule the board-wide stale-snapshot banner uses, so the sign and the banner agree.
- **freshness-no-probe**: Under the shared check, a missing or empty `lastCycleAt` or `generatedAt` MUST yield `"fresh"` — no probe yet means nothing to judge, so no alarm.
- **freshness-window**: Under the shared check, the stale window MUST be `max(probeIntervalMs × 5, 300,000 ms)`, with a null or missing `probeIntervalMs` treated as 0 (so the window is the 300,000 ms floor).
- **freshness-lag**: Under the shared check, the lag MUST be measured as the parsed timestamp of `generatedAt` minus the parsed timestamp of `lastCycleAt`, both server clocks, and MUST NOT involve the client's current time.
- **freshness-threshold**: Under the shared check, a lag not strictly greater than the window MUST be `"fresh"`; a lag greater than the window MUST be `"stale"`, escalating to `"very-stale"` when greater than three times the window. Both non-fresh verdicts count as stale for Portfolio Indicator.
- **freshness-unparseable**: Under the shared check, an unparseable date (an invalid lag) MUST yield `"fresh"`, because a comparison against an invalid value defaults to not-stale.

### Derivation

- **unknown-when-offline**: `pillKey` MUST be `"unknown"` when Live Snapshot's `offline` is true.
- **unknown-when-blind**: `pillKey` MUST be `"unknown"` when Live Snapshot's `blind` is true (the last snapshot monitored no endpoints).
- **unknown-when-no-board**: `pillKey` MUST be `"unknown"` when `board` is null.
- **unknown-when-snapshot-stale**: `pillKey` MUST be `"unknown"` when the snapshot is stale per **snapshot-stale-rule**.
- **independent-feeds**: Any single one of the four unknown conditions MUST be sufficient on its own: the live transport and the board poll fail independently, and either one alone going stale is real information the other can't stand in for.
- **mapped-verdict**: When none of the unknown conditions holds, `pillKey` MUST be the mapped value of `board.indicator`: `"operational"` maps to `"ok"`, `"degraded"` to `"warn"`, and `"outage"` to `"down"`.
- **server-verdict-only**: Portfolio Indicator MUST NOT compute the colour from the problems list; the non-unknown `pillKey` MUST come solely from the server-assigned `board.indicator`.
- **count-from-board**: `count` MUST be `board.problems.length` whenever `board` is non-null, including when `pillKey` is `"unknown"` because the live feed is offline, blind or stale.
- **count-no-board**: `count` MUST be `0` when `board` is null.

### Execution, caching and side effects

- **pure-derivation**: Portfolio Indicator MUST perform no side effects of its own: no fetches, timers, storage writes, logging or subscriptions beyond those the board state and Live Snapshot perform.
- **no-memoisation**: Portfolio Indicator MUST recompute `pillKey` and `count` every time its inputs are read and MUST NOT cache or retain a previous verdict; a null board renders `"unknown"`, never the last verdict.
- **render-thread**: Portfolio Indicator MUST run synchronously, on a single execution thread; it has no asynchronous work and no ordering concerns of its own.
- **provider-precondition**: Portfolio Indicator MUST be used only where the shared cache context and the status API context its two inputs require are available; this is a caller precondition inherited from the board state and Live Snapshot.

