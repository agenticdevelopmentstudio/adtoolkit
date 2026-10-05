
**Decision**: Split the classification out of the roster query into its own key.
**Rationale**: The source records that one flaky provider in the old five-leg combined read emptied Settings ▸ Sites and Settings ▸ Platforms while the rows sat readable in local storage; the rosters must not depend on a third party being up.
**Approved**: pending

**Decision**: Keep reporting the classification failure through `error` while `isLoading` tracks rosters only.
**Rationale**: "A dead classification must never be read as zero gaps / all clear", but it "no longer parks the editor in a permanent skeleton". Roster-first precedence means a double failure surfaces only the roster error.
**Approved**: pending

**Decision**: Take the project axis whole from the server; derive the endpoint axis locally.
**Rationale**: The server is the single source of truth for which projects need monitoring; the endpoint axis stays local because the banner needs each endpoint's url, site and environment, which the server's `{id,name}` shape omits, and the raw endpoints are already loaded for the editor.
**Approved**: pending

**Decision**: Fold `isActive === false` into the engine's `ignoreProjectWarning` at the app boundary.
**Rationale**: `isActive` means nothing to the engine's other consumers; the server applies the identical fold in its own adapter (`autoConfigureOptedOut`), so client and server agree on the same endpoint.
**Approved**: pending

**Decision**: Return `EMPTY_STATUS` until both queries have data.
**Rationale**: Status assembly needs both halves to produce a consistent model; the trade-off, recorded under Edge Cases, is that a pending classification is indistinguishable from zero gaps through `status` alone.
**Approved**: pending

**Decision**: Use the cache-served classification request (no `fresh`) with no automatic refresh interval.
**Rationale**: The source says the badges' refresh "coalesces on" the server's 30-second single-flight cache instead of fanning out a provider scan per tab per minute; only the Auto Configure modal forces a fresh scan.
**Approved**: pending

