
**Decision**: History fetches through the client's raw request method and checks whether the response is ok itself, instead of calling its JSON-body helper.

**Rationale**: The source chooses the raw method and produces its own short `history <status>` message. As a result, it drops the server's error detail and treats a no-content response as a parse failure. Both are deliberate consequences of that choice, recorded here so ports keep them.

**Approved**: pending

---

**Decision**: The history window is fixed at 24 hours.

**Rationale**: The consuming pane labels itself `Response time · 24h`, and History hard-codes `hours=24` to match. A different window would need a new parameter.

**Approved**: pending

---

**Decision**: Cache, retry, and refresh policy are left to the shared cache.

**Rationale**: History sets only its cache key, its read step, and whether it is enabled. Tests in the package build their cache with retries disabled, and production hosts supply their own defaults. A port MUST get its retry and staleness from the equivalent app-level policy rather than hard-coding them in History.

**Approved**: pending

