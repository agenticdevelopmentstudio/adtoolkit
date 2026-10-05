
**Decision**: `rowToDetailProps` copies StatusRow's title-link precedence exactly.
**Rationale**: The doc comment says the row and the details pane must "always agree on titles/links". An endpoint is its checked URL (`liveUrl` first), and a deploy's title links to its deployment page (`sourceUrl` first).
**Approved**: pending

**Decision**: The status word is rendered exactly as the server sent it, and the function takes no clock.
**Rationale**: The doc comment says the client-side freshness demotion this function used to apply is gone, and its `nowMs` parameter with it. The server's verdict is the only verdict.
**Approved**: pending

**Decision**: The problem field is dropped when it equals the commit subject.
**Rationale**: Deploy-status issues set `detail` to the commit's first line. Showing it twice adds nothing, because the commit field already shows it.
**Approved**: pending

**Decision**: `platformLink` points at the deployment page.
**Rationale**: The source comment says only the specific deployment URL is stored and no project-level dashboard URL can be derived from the provider metadata, so the deployment page is the closest deployments context available.
**Approved**: pending

**Decision**: `since` prefers `downSince` and falls back to the row's event time.
**Rationale**: The list only carries a relative label. The pane always shows an absolute time, and the server-truth down-since is durable across browsers.
**Approved**: pending

**Decision**: An explicit set (`crunchy`, `glitchtip`) is excluded from the deploy outcome.
**Rationale**: Crunchy rows are database-cluster health mapped onto deploy phases, and GlitchTip rows are application errors. Neither built nor deployed anything, so a "build / deploy FAILED" headline would name an event that did not happen, and the pane's `logs` label would present an exception list as a build log. The platform name cannot tell them apart, because it is truthy for every registered source.
**Approved**: pending

**Decision**: The copy text puts the error text in its own block and ends with the full commit body.
**Rationale**: The source comment says the error text is "the whole point of the copy (paste straight into an LLM) and may be multi-line", so it gets a labeled block. The body is appended only when it adds to the subject.
**Approved**: pending

