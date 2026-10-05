
**Decision**: Start at the default (all selected) and hydrate from storage after the initial state settles, rather than reading storage while establishing that initial state.

**Rationale**: The source comment states it keeps "SSR/first-paint match": a server render has no `localStorage`, so reading it during that render would make the client's first render differ from the server's HTML. The Activity TTL and Build Progress concepts cite this concept as the pattern they mirror.

**Approved**: pending

**Decision**: Hydration filters stored names against `ENVIRONMENTS` but `toggle` does not validate its argument.

**Rationale**: Stored data is untrusted (older builds, hand edits, a removed environment), so it is filtered on read. `toggle` is only called with names from `all` by its one consumer, so the source leaves the check out; the filter on the next hydration repairs any stray name.

**Approved**: pending

**Decision**: A stored array whose entries are all invalid, or an empty array, hydrates to an empty selection rather than the default.

**Rationale**: The source applies the filter result directly whenever the parsed value is an array; only a missing, non-array or unparseable value falls back to the default. A port MUST keep this distinction to behave identically after reload.

**Approved**: pending

**Decision**: Storage read and write failures are caught and discarded without logging.

**Rationale**: The source comments say "localStorage unavailable / bad JSON — keep the default" and "ignore persistence failure". The filter is a convenience preference; the in-memory selection keeps the page fully usable, and losing it on reload is the accepted cost.

**Approved**: pending

**Decision**: No cross-tab change listener and no shared store across instances.

**Rationale**: The source registers none; the Overview mounts one instance, so per-instance state is sufficient. Cross-tab or cross-instance sync would be a new feature, not part of this contract.

**Approved**: pending

