
**Decision**: Stores are named for the concern the existing code expresses (Config, Auth, Token, Health, etc.) rather than an invented grouping.

**Rationale**: Each store is a discrete concern with its own contract; naming by concern makes the interface self-documenting and helps porting teams map their own persistence layer.

**Approved**: pending

---

**Decision**: Token and session storage is hash-only; raw values are shown to callers exactly once and never persisted, except the device grant's `tokenRaw`, held on the grant row only until the single-use consume.

**Rationale**: Hashing by default prevents accidental logging or leakage of secrets in error messages, logs, or database dumps. The caller is responsible for storing the raw value (e.g., as an Authorization header) immediately after mint.

**Approved**: pending

---

**Decision**: Page readers (readDeployActivityPage, readIssueOpenedPage) return `SourcePage<T>` with `floorMs` to handle pagination boundaries that cross multiple rows with the same timestamp.

**Rationale**: A LIMIT cut may split a tie group; the reader re-reads that group in full so a partial instant is never returned, and `floorMs` (null when the source is exhausted) informs the next cursor. This is a storage concern, not a caller concern.

**Approved**: pending

---

**Decision**: Last-admin protection is atomic; setUserRoleGuarded and deleteUserGuarded return 'blocked' rather than throwing.

**Rationale**: Race-free protection without requiring callers to catch exceptions; the return value signals the guard was hit.

**Approved**: pending

---

**Decision**: ConfiguredEndpoint is a flattened type combining endpoint, site, and group data; callers do not reconstruct it.

**Rationale**: Probes and the /api/live endpoint read this shape; the adapter performs the endpoint-site-group inner join once in `listActiveEndpoints`, so no caller repeats it.

**Approved**: pending

