
**Decision**: Hide every concrete backend behind ports, and select adapters only in the composition root `client.ts`.
**Rationale**: Per the `ports.ts` and `client.ts` comments, reconnecting the Turso backend means changing one line (`SOURCES.live` to `SOURCES.turso`), and the hook, cache and panels do not change because both sources honor the same `TelemetrySnapshot` contract.
**Approved**: pending

**Decision**: Wire the live `/telemetry` source by default instead of the database-backed one.
**Rationale**: `live.ts` states that there is "No database anywhere on this path: a Turso outage cannot affect the dashboard's errors/analytics".
**Approved**: pending

**Decision**: Persist the last snapshot in localStorage, and make saving best-effort.
**Rationale**: The cache gives instant paint on reload and a last-known view during a brief source outage. The in-memory query result stays the live truth, so a failed write loses only the reload shortcut.
**Approved**: pending

**Decision**: Gate stored snapshots only at the top level, and project them to the three known fields.
**Rationale**: The comment "Defensive, shape-gated parse" favors never throwing over full validation. The `-v1` key suffix allows a future shape change to start clean. The pure `parseSnapshot` is split out so it can be tested without a browser.
**Approved**: pending

**Decision**: `FetchResult.ok = false` must never clear a store.
**Rationale**: The `ports.ts` doc comment warns that an empty list from a failed poll is not "no data", and wiping the store during a temporary provider outage would blank the band.
**Approved**: pending

**Decision**: `tursoSource` stamps `generatedAt` on the client.
**Rationale**: `/errors` and `/analytics` return no snapshot timestamp, so the source records when it assembled the snapshot. As a result, Turso-path `generatedAt` values follow client-clock semantics, while live-path values follow the server clock.
**Approved**: pending

