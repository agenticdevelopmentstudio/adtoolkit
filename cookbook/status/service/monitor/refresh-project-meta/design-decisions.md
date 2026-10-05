
- **Decision**: make `deploy_project_meta`'s Vercel rows a mirror of the fetched
  account snapshot (upsert plus matching eviction) instead of the previous
  upsert-only table.
  **Rationale**: stated directly in the source's own module comment — the
  upsert-only table meant a deleted Vercel project "was enumerated forever,"
  Auto Configure "kept being offered" it, and its "dead deploy target reopened
  an unclearable Problem"; making this file "the ONLY writer" closes that gap
  "so the prune can never drift from the upsert."
  **Approved**: pending
- **Decision**: gate the eviction attempt on `snapshot.configured` rather than
  on `snapshot.meta.length > 0`.
  **Rationale**: an account whose last project was deleted returns a genuinely
  empty `meta` array from a genuinely authenticated, complete read; treating
  emptiness itself as "not configured" would make that real deletion
  unrepresentable and would never evict the account's last remaining stored
  row — the source's own reasoning is that `configured` "is deliberately NOT
  inferred from `meta.length > 0`."
  **Approved**: pending
- **Decision**: diff stored-vs-live names in JavaScript and delete by an
  explicit, chunked name list, rather than issuing one SQL `NOT IN` (`notInArray`)
  query against the live set.
  **Rationale**: not stated as a deliberate tradeoff in an inline comment;
  demonstrated as a fact of the code, since `deleteProjectMeta` receives an
  explicit `pruned` array rather than the `live` set or a subquery. Recorded
  here per source-fidelity as fact: this keeps the eviction bound by
  `DELETE_CHUNK_NAMES` the same way the upsert is bound by
  `UPSERT_CHUNK_PROJECTS`, at the cost of one extra `listProjectMetaNames`
  round-trip that a single `NOT IN` delete would not need.
  **Approved**: pending
- **Decision**: use no grace window or TTL before evicting a name absent from a
  complete, authenticated read.
  **Rationale**: stated directly in the source's own module comment — "an
  erroneous eviction is repaired by the next cycle's upsert (5 minutes)," so a
  spurious eviction from a transient API omission self-heals on the next
  monitor cycle rather than needing a deliberate hold-back window in this file.
  **Approved**: pending

**Decision**: Concurrent project-metadata syncs are not serialized and can interleave their upsert, listing and prune steps.
**Rationale**: It stands today because the three storage calls are independent. Closing it needs a transaction or a single-flight guard around the reconcile, and a test with two overlapping invocations.
**Approved**: pending

