
**Decision**: Demote a stale in-flight deploy to "total only" in `summarizeByPlatform`, using the same `deployDtoUnconfirmed` rule as `DeployList` and the activity list.
**Rationale**: Per the doc comment, an in-flight deploy that nothing has re-confirmed is no longer a live "building". Counting it would let the Build-pipeline pane and the KPI building pill assert progress the rest of the board has stopped asserting.
**Approved**: pending

**Decision**: Correlate endpoints to deploys only by the explicit (platform, project) configured on the endpoint, never by host.
**Rationale**: The section comment says "No host guessing." An endpoint with no platform or project wired is a health-only check and correlates to nothing.
**Approved**: pending

**Decision**: Re-export `deployTargetKey` and `platformCanon` from the shared canon package rather than restating them.
**Rationale**: The server keys deploys with `deployTargetKey`. A previous local copy omitted the environment lowercasing, so a Railway endpoint whose stored environment differed in case correlated to nothing in the browser while the server matched it.
**Approved**: pending

**Decision**: Match the environment only for Railway.
**Rationale**: Railway serves every environment from one project. Vercel and Cloudflare projects are environment-specific, so the project alone identifies them.
**Approved**: pending

**Decision**: `latestTerminalForEndpoint` skips canceled and in-flight deploys.
**Rationale**: Per its doc comment, the deploy status shown should reflect the last real outcome, not a canceled or in-flight build on top of it.
**Approved**: pending

**Decision**: `summarizeByPlatform` groups by the raw platform string, while the endpoint helpers canonicalize.
**Rationale**: This is how the source behaves. Summary sections are keyed by the platform string on the deploy row (`"cloudflare-pages"` is the one in `PLATFORM_ORDER`). Correlation has to bridge the config spelling `"cloudflare"`. A port that canonicalizes in the summary would change section keys and ordering.
**Approved**: pending

**Decision**: Export `PLATFORM_ORDER` as the single ordering source.
**Rationale**: Per the source comment, every platform-grouped surface should order sections identically, instead of each keeping its own list.
**Approved**: pending

