
**Decision**: Fold read staleness, data freezing and absent observations into `board === null` inside the hook, instead of leaving `isBoardStale` for each consumer to call.
**Rationale**: Per "Fix Round 3 item 1", three separate rounds produced the same bug: a consumer checked `board === null` but not staleness and rendered a confident verdict off a frozen read. Making null mean "cannot back a current claim" gives every consumer the right answer by construction.
**Approved**: pending

**Decision**: Keep `stale`, `frozen` and `no-data` as distinct reasons even though all three produce a null board.
**Rationale**: Per the `BoardUnavailableReason` doc comment, they send a human to different places (the API, the monitor process, the config); `no-data` was split out ("Fix Round 2 item C3") because it is the normal state of a roster with nothing to observe and was misreported as a wedged monitor.
**Approved**: pending

**Decision**: Expose no `isLoading` flag; `reason === "loading"` is the only loading signal.
**Rationale**: A second way to ask the same question is the shape that caused the three-round bug above (doc comment on `reason`).
**Approved**: pending

**Decision**: Retry a failed read once (`retry: 1`) instead of React Query's default three retries with backoff.
**Rationale**: Per "Fix Round 2 item 5", the board already polls every 60 s, so extra retries only delay surfacing a down backend behind a longer spinner; one retry absorbs a single transient blip, and it matches the sibling `useLiveSnapshot` feed that gates the same loading screen.
**Approved**: pending

**Decision**: Judge the read clock against the client clock but the data clock server-against-server, using the cadence carried on the board being judged.
**Rationale**: The client clock keeps moving when every server feed has died, which is the failure the read check exists to catch; the data check compares two server timestamps so it is immune to client skew and throttled timers. The cadence used to come from the live-snapshot singleton, which was null for consumers that never open the SSE stream and silently widened the window ("One board, one answer").
**Approved**: pending

**Decision**: Hold no durable client state (no `localStorage`).
**Rationale**: Per the `useBoard` doc comment, a durable client store let a fixed problem survive in one browser tab forever, because a server-side fix could not reach into the tab's saved state.
**Approved**: pending

**Decision**: Use live frames as the fast path and the 60 s poll as the floor, without opening a second connection.
**Rationale**: The board and the snapshot change at the same moments and "one connection per tab is the existing contract" (`subscribeLiveFrames` doc comment); the poll keeps the board updating when the stream is down.
**Approved**: pending

