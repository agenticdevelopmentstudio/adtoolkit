
### Types and constants

- **freshness-type**: `SnapshotFreshness` MUST be the string union `"fresh" | "stale" | "very-stale"`.
- **stale-floor**: `SNAPSHOT_STALE_FLOOR_MS` MUST equal 300 000 ms (`5 * 60_000`). It is both the window floor and the window used when the backend reports no interval (an older backend that predates the `probeIntervalMs` field).

### snapshotStaleMs

- **window-signature**: `snapshotStaleMs` MUST take an optional `probeIntervalMs?: number | null` and MUST return a number of milliseconds.
- **window-formula**: `snapshotStaleMs` MUST return `Math.max((probeIntervalMs ?? 0) * 5, SNAPSHOT_STALE_FLOOR_MS)`.
- **window-unknown-interval**: `snapshotStaleMs` MUST return 300 000 when `probeIntervalMs` is `undefined` or `null`.
- **window-small-interval**: `snapshotStaleMs` MUST return 300 000 for any `probeIntervalMs` at or below 60 000 (including `0` and negative values), because five times it does not exceed the floor.
- **window-scaling**: `snapshotStaleMs` MUST return exactly `probeIntervalMs * 5` for any `probeIntervalMs` above 60 000, with no upper cap.
- **window-mirrors-scheduler**: The window formula MUST stay identical to the backend scheduler's default `staleAfterMs` (`Math.max(intervalMs * 5, 300_000)`), so a raised `PROBE_INTERVAL_SECONDS` does not make one skipped cycle trip the verdict. The backend value is owned by `status-server/src/scheduler.ts`; this module duplicates the formula rather than importing it.

### snapshotFreshness

- **freshness-signature**: `snapshotFreshness` MUST take `lastCycleAt: string | null | undefined`, `generatedAt: string | null | undefined` and an optional `probeIntervalMs?: number | null`, and MUST return a `SnapshotFreshness`.
- **missing-last-cycle**: `snapshotFreshness` MUST return `"fresh"` when `lastCycleAt` is `null`, `undefined` or the empty string, before parsing either timestamp. Per the source comment this is "no probe yet (zero-endpoint monitor)": nothing to judge, so no alarm.
- **missing-generated-at**: `snapshotFreshness` MUST return `"fresh"` when `generatedAt` is `null`, `undefined` or the empty string ("no read clock").
- **lag-computation**: `snapshotFreshness` MUST compute the lag as `Date.parse(generatedAt) - Date.parse(lastCycleAt)`.
- **server-clock-only**: `snapshotFreshness` MUST NOT read the client clock (`Date.now()` or a timer). Its verdict depends only on its arguments, which makes it immune to client clock skew and to throttled timers in a sleeping tab.
- **fresh-at-or-below-window**: `snapshotFreshness` MUST return `"fresh"` when the lag is less than or equal to `snapshotStaleMs(probeIntervalMs)`. The comparison is strict, so a lag exactly equal to the window is fresh.
- **negative-lag-fresh**: `snapshotFreshness` MUST return `"fresh"` when the lag is negative (the probe timestamp is newer than the read clock). The function applies no lower bound.
- **nan-fails-open**: `snapshotFreshness` MUST return `"fresh"` when the lag is `NaN`, which happens when either timestamp is unparseable. The source tests `!(ageMs > staleMs)` rather than `ageMs <= staleMs` precisely so a `NaN` comparison falls through to `"fresh"` instead of showing a banner.
- **stale-band**: `snapshotFreshness` MUST return `"stale"` when the lag is strictly greater than the window and less than or equal to three times the window.
- **very-stale-band**: `snapshotFreshness` MUST return `"very-stale"` when the lag is strictly greater than three times the window.
- **not-cycle-health**: `snapshotFreshness` judges only the freshness of the newest persisted probe. It MUST NOT be used as the scheduler's cycle-completion health, which the backend reports separately at `/health`. The doc comment notes a downstream cycle stage can hang after probes were written while the on-screen data is still current.

### Caller contract

- **caller-banner-tone**: A caller that renders a banner MUST map `"stale"` to the amber tone and `"very-stale"` to the red tone, and render nothing for `"fresh"`. This is how `SnapshotStaleBanner` consumes the verdict.
- **caller-indicator-unknown**: A caller that renders an overall status sign MUST treat any verdict other than `"fresh"` as "cannot back a confident status claim". `usePortfolioIndicator` folds it into its unknown state.
- **refresh-by-repoll**: The verdict only grows while the poller is wedged because the client re-pulls `/live` on its own interval and each fresh snapshot re-stamps `generatedAt`, while `lastCycleAt` stays frozen. The module itself MUST NOT schedule anything; re-evaluation is the caller's job on each new snapshot.

### Purity and concurrency

- **pure-functions**: Both exported functions MUST be pure and synchronous. They MUST NOT perform I/O, log, throw on any input of the declared types, or mutate state.
- **single-threaded**: The module holds no state and runs on the single JavaScript thread, so concurrent calls cannot interleave and it needs no ordering rule.

