
**Decision**: Links are derived from real configuration only; no guessing.

**Rationale**: When a monitored site lacks a platform identifier or team ID, the module returns `null` rather than constructing a plausible-looking but unverified URL. This prevents users from being directed to incorrect dashboards and makes it clear to calling code when a link cannot be built. The pattern forces upstream code to handle the `null` case explicitly, avoiding silent failures.

**Approved**: pending

**Decision**: Production endpoint is preferred; fallback to first endpoint.

**Rationale**: Many monitoring scenarios have multiple endpoints (staging, canary, production). The production environment is the canonical live site; preferring it by environment tag ensures the most commonly used URL is returned. Falling back to the first endpoint when no production tag exists handles the common case of single-endpoint deployments without requiring the caller to specify a default.

**Approved**: pending

**Decision**: Platform canonicalization is delegated to `platformCanon()`.

**Rationale**: Platforms are sometimes aliased (e.g., `cloudflare-pages` vs. `cloudflare`). Centralizing canonicalization in a single function (defined in the monitor submodule) ensures consistency across the codebase and allows the canonicalization rules to be updated in one place.

**Approved**: pending

