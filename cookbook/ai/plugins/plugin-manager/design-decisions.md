
**Decision**: Loading a plugin caches one instance per identifier for the manager's lifetime instead of creating a fresh instance per call, even though the plugin protocol's own doc comment says "Instances are cheap and may be created per request."
**Rationale**: Caching avoids repeating the bundle-load/principal-class resolution on every request and keeps the loaded-bundles bookkeeping simple (one bundle reference per identifier); since macOS never truly unloads a loaded bundle's binary anyway (per `unload-retains-bundle`), there is no memory cost to keeping one instance alive alongside it. (Apple platform implementation.)
**Approved**: pending

**Decision**: A duplicate identifier discovered from a later search path is dropped silently, with the earlier one always winning.
**Rationale**: The source's own comment on the app-name initializer states the search-path order is deliberate — "the bundle's own copy wins, then the hand-filled dotfolder, then what an installer wrote" — so first-discovered-wins is how that stated precedence is implemented, not an oversight.
**Approved**: pending

**Decision**: Unloading a plugin removes the cached instance but leaves its bundle cached forever.
**Rationale**: The source's own comment states "the bundle remains loaded in memory (macOS does not support unloading bundles)" — since the OS will not release the mapped binary regardless, removing the bundle reference would only lose the manager's own bookkeeping for no memory benefit. (Apple platform implementation.)
**Approved**: pending

**Decision**: A search-path entry that cannot be enumerated is skipped silently.
**Rationale**: Unlike every other skip branch in discovery, no warning is logged and nothing is surfaced to the caller; closing the gap takes whoever owns the manager's callers deciding whether an enumeration failure should log, be surfaced through a return value, or stay silent.
**Approved**: pending

**Decision**: An empty app name is not validated.
**Rationale**: An empty app name widens the search to the shared plugins location, a risk documented only in the helper the manager calls and not enforced at this call site; closing the gap takes confirming whether the app name can ever be empty before app metadata is configured, and if so rejecting it (an assertion) or defaulting it.
**Approved**: pending

