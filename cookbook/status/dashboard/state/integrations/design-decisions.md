
**Decision**: Integrations fetches through the client's raw request method and checks whether the response is ok itself, instead of calling its JSON-body helper.

**Rationale**: The source picks the raw method and produces its own short `status <status>` message. That drops the server's error detail, gives a message that does not name the endpoint, and treats a no-content response as a parse failure. All three follow from that one choice and are recorded here so ports keep them. A port SHOULD keep the message format so logs match across platforms. It MAY add the endpoint name only if every sibling concept's port does the same.

**Approved**: pending

---

**Decision**: The query refreshes on returning focus, and its periodic refresh is left to Refresh All.

**Rationale**: The integration self-check is the monitor's own health, which the Overview shows on the default wallboard "so a broken monitor can't hide". Integrations turns on refresh-on-returning-focus so a returning viewer sees a current verdict. It sets no automatic refresh interval because Refresh All refreshes all supporting queries together, "so the dashboard never shows a mix of fresh + stale datasets".

**Approved**: pending

---

**Decision**: Staleness, cache lifetime and retry policy are left to the shared cache.

**Rationale**: Integrations sets only its cache key, its read step and refresh-on-returning-focus. Tests in the package build their cache with retries disabled, and production hosts supply their own defaults. A port gets retry and staleness from the equivalent app-level policy.

**Approved**: pending

