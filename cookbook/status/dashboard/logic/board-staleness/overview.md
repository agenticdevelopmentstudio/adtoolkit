
`board-staleness.ts` (`packages/web/packages/status-web/src/lib/board-staleness.ts`) is the status dashboard's single owner of the rules that decide whether a `Board` read can still back a current claim. It exports two constants for the board's poll cadence and read-staleness threshold, a constant and a function for the cadence-scaled data-clock window, a three-valued `BoardDataFreshness` type, and two pure predicates:

- `isBoardStale(generatedAt, nowMs)` catches a board read that has stopped ARRIVING. It compares the board's `generatedAt` against the client clock.
- `boardDataFreshness(dataAsOfMs, generatedAt, probeIntervalMs?)` catches a board that keeps arriving over frozen FACTS. It compares two server clocks: `generatedAt` minus `dataAsOfMs`.

Per the module's doc comment, the two rules compose and "neither can substitute for the other". The module has no state, no I/O and no side effects. Its one call site is the `useBoard` hook ([useBoard](adtoolkit://cookbook/status/dashboard/state/board)), which folds both verdicts into `board === null` with a reason. The data-clock window is derived from `snapshotStaleMs` in the sibling `snapshot-staleness.ts`, so board and snapshot freshness share one "how old is too old" rule.

