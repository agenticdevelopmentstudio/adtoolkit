
**Decision**: The "status unknown" rule lives in one shared concept used by every portfolio-wide sign.
**Rationale**: Sharing the derivation keeps the "when is status unknown" rule in one place so the two signs can never disagree.
**Approved**: pending

**Decision**: Snapshot staleness and board staleness are separate unknown conditions.
**Rationale**: The live transport and the board poll fail independently, and either one alone going stale is real information the other can't stand in for.
**Approved**: pending

**Decision**: Portfolio Indicator trusts a null board and computes no board-staleness term of its own.
**Rationale**: Board staleness was moved into the board state, so a null board already covers both "never arrived" and "gone stale" by construction, the same way every other consumer of the board state now does; a second check here would be a consumer re-deriving a rule its input already applies.
**Approved**: pending

**Decision**: A null snapshot counts as fresh, not unknown.
**Rationale**: A null `lastCycleAt` (no probe yet) is fresh, so a healthy monitor is unaffected; the board, not the snapshot, is the thing that must have come back before a colour is claimed.
**Approved**: pending

**Decision**: `count` is taken from the board even when `pillKey` is `"unknown"`.
**Rationale**: The board's problem count is independent of the unknown test; callers decide whether to show a count beside an unknown glyph.
**Approved**: pending

**Decision**: Staleness compares two server timestamps rather than the client clock.
**Rationale**: Measuring `generatedAt - lastCycleAt` is immune to client clock skew and to client timers being throttled while a tab sleeps. This rationale applies as written to a client that has such a timer-throttling concern (the web platform); a port on a platform without it keeps the two-server-timestamp comparison regardless, since it is also immune to simple client clock skew.
**Approved**: pending

