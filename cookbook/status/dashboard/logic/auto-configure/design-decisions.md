
**Decision**: The browser runs the shared engine through an adapter rather than its own planner. (Written from the browser adapter's perspective; the same reasoning applies to every platform's port.)
**Rationale**: The header comment calls a second copy "one piece of knowledge in two places with nothing checking they agree". The browser and the server could otherwise file the same project under different sites.
**Approved**: pending

**Decision**: Match-only is a property of the call (no `create` passed), not of a crippled port. The create methods stay wired.
**Rationale**: Creation needs a transaction-scoped view of every site, so it can pick the group that owns a domain family and disambiguate a taken slug. Only the server has that view. A port that threw for half its methods would trap the next caller.
**Approved**: pending

**Decision**: `runMatch` has no hidden default network client, so `opts.client` is required when `opts.api` is absent. (React/Web implementation — `runMatch`, `opts.client`, `opts.api`, and `requireClient` are this module's own names.)
**Rationale**: The doc comment on `requireClient` says there is "no hidden default network client to fall back on silently". This keeps tests from accidentally reaching the network.
**Approved**: pending

**Decision**: The opt-out fold (`ignoreProjectWarning || !isActive`) happens in the adapter, not in the engine.
**Rationale**: Dropping the flag once made the endpoint axis wire every opted-out monitor. `isActive` means nothing to the engine's other consumers, so the fold belongs at the boundary, matching the server's adapter.
**Approved**: pending

**Decision**: The detail blocks are capped at 5 named rows with a remainder count, and are kept separate from `summarizeAutoConfigure`.
**Rationale**: Counts alone let "a permanently stuck project" stay "invisible behind a bare `skipped: 1`", while an uncapped list would turn the dialog into a log dump. The summary function describes what the engine did; these blocks are the diagnostic beside it.
**Approved**: pending

**Decision**: The notes header is the neutral `Also:`.
**Rationale**: Two different caveats share the block: a site filed under its domain family's group, and a monitor taken over from a retired project. The source says "a header naming only one of them mislabels the other — a wrong explanation is worse than none."
**Approved**: pending

