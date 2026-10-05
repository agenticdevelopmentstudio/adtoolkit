
**Decision**: Hydrate from the cache in a post-mount effect, not during render or as react-query `initialData`.
**Rationale**: The source comment says this keeps "SSR and the first client paint" identical; reading `localStorage` during render would produce a hydration mismatch. The cost is one render of the empty snapshot before the cached one appears.
**Approved**: pending

**Decision**: Return a plain snapshot with fixed precedence live, then cached, then empty.
**Rationale**: "Live data wins; the cached snapshot covers the gap before the first poll lands (and a brief source outage); empty until either arrives." Consumers never handle `undefined`. The trade-off, recorded as the open question on telemetry-failure-signal, is that no error or staleness signal reaches consumers. In practice react-query retains the last data on error, so within one session an outage is covered by retained query data rather than by the cache; the cache covers the gap after a reload.
**Approved**: pending

**Decision**: Depend only on the `TelemetrySource` and `SnapshotCache` ports, composed in `telemetry/client.ts`.
**Rationale**: The source says swapping the backend (live poll versus Turso) is a one-line change in the composition root that "leaves it untouched"; `ports.ts` states that "nothing above the port moves".
**Approved**: pending

**Decision**: Treat the `localStorage` write as best-effort and the stored value as untrusted.
**Rationale**: `local-cache.ts` says "the in-memory query result is the live truth", so a failed write is silently ignored; `parseSnapshot` is a "defensive, shape-gated parse" because a stored value may be stale, from an older build, or corrupt.
**Approved**: pending

**Decision**: Poll every 60 seconds with one retry and focus refetch.
**Rationale**: `TELEMETRY_POLL_MS = 60_000` with `retry: 1` bounds each poll to at most two requests to `/telemetry`, which on the live path makes the server poll GlitchTip and PostHog; the source records no further rationale for the specific values.
**Approved**: pending

**Decision**: The telemetry state exposes no error or staleness signal; a never-answered source looks like an empty snapshot.
**Rationale**: It stands today because the state's contract is the snapshot alone. Closing it needs the owner to decide whether the contract should expose an error or staleness signal, and tests for both.
**Approved**: pending

