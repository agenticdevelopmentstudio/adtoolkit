
- **Decision**: confirm a failure only when both the run count AND the wall-clock window are satisfied, rather than either alone.
  **Rationale**: stated directly in the module's own doc comment — "the check runs on demand (every /integrations request), so a run count alone could be satisfied by two polls seconds apart inside one blip — the failure must also span real time."
  **Approved**: pending
- **Decision**: make recovery immediate (a single non-debounce-eligible run clears the streak) while confirmation is debounced across `CONFIRM_RUNS` runs and `CONFIRM_WINDOW_MS`.
  **Rationale**: stated directly in the module's own doc comment — "Recovery is not debounced — one good run clears the streak." Demonstrated by status-server-monitor-self-check-stability-004.
  **Approved**: pending
- **Decision**: correlate simultaneous confirmed failures into one synthetic Connectivity warning instead of leaving each provider red.
  **Rationale**: stated directly in the module's own doc comment — "When several providers are confirmed-unreachable in the SAME run, the outage is almost certainly ours, not theirs... a single synthetic Connectivity check names the real suspect, so the banner shows one amber chip instead of a wall of red provider errors." Demonstrated by status-server-monitor-self-check-stability-005.
  **Approved**: pending
- **Decision**: leave duplicate ids within one `checks` array unvalidated and unguarded.
  **Rationale**: not stated in an inline comment; the one production caller (`integrations.ts`) always supplies seven statically distinct ids, so no shipped call site can trigger the duplicate-id, sequential-double-counting fact recorded under Edge Cases. Recorded here per source fidelity as fact, not endorsement.
  **Approved**: pending
- **Decision**: keep this recipe's own Behavioral Requirements scoped to `self-check-stability.ts`'s contract, and cross-reference — rather than repeat — how `status-server-monitor-integrations` wires and shares one instance of it.
  **Rationale**: `self-check-stability.ts` is a small, self-contained factory (three constants, one factory function, roughly forty lines); the module-level-singleton topology that shares one `SelfCheckStabilizer` across every `/integrations` request belongs to `integrations.ts`'s own wiring and is already documented on `status-server-monitor-integrations` under its "Cross-Run Stabilization" section, so restating it here would let the two recipes drift out of sync on the same fact.
  **Approved**: pending

