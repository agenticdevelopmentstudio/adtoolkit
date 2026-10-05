
`snapshot-staleness.ts` (`packages/web/packages/status-web/src/lib/snapshot-staleness.ts`) is the status dashboard's single staleness rule for the live snapshot: "how stale the displayed status data is". It exports a three-valued `SnapshotFreshness` type, the constant `SNAPSHOT_STALE_FLOOR_MS`, the window function `snapshotStaleMs`, and the verdict function `snapshotFreshness`.

The doc comment calls it "the ONE staleness rule". It is shared by the board-wide `SnapshotStaleBanner` component and the [usePortfolioIndicator](adtoolkit://cookbook/status/dashboard/state/portfolio-indicator) hook, so the banner and the header/home status sign can never disagree. Both callers read `lastCycleAt`, `generatedAt` and `probeIntervalMs` off the snapshot held by [useLiveSnapshot](adtoolkit://cookbook/status/dashboard/state/live-snapshot). The sibling [Board Staleness](adtoolkit://cookbook/status/dashboard/logic/board-staleness) module derives its data-clock window from `snapshotStaleMs`.

The lag is measured server clock against server clock: the snapshot's `generatedAt` (stamped at read time) minus its newest persisted probe `lastCycleAt`. The window mirrors the backend scheduler's `staleAfterMs` (`max(interval×5, 5min)` in `status-server/src/scheduler.ts`). The module has no state, no I/O and no side effects.

