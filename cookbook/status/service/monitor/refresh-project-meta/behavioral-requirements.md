
- **sole-writer-of-vercel-rows**: `syncVercelProjectMeta` MUST be the only code
  path that writes a `platform: 'vercel'` row into `deploy_project_meta`, so that
  every eviction it computes reflects every upsert that has ever landed; the
  source's own module comment states this design intent explicitly.
- **unconditional-upsert-on-nonempty-meta**: `syncVercelProjectMeta` MUST call
  `storage.deploy.upsertProjectMeta` whenever `snapshot.meta.length > 0`,
  tagging every row `platform: 'vercel'`, regardless of `snapshot.ok` or
  `snapshot.configured` — a partial (`ok: false`) read still upserts the
  projects it did get, because "a real build failure must not be lost."
- **no-eviction-attempt-when-not-ok-or-not-configured**: `syncVercelProjectMeta`
  MUST return `{ pruned: [], live: null }` immediately, without calling
  `storage.deploy.listProjectMetaNames` or `storage.deploy.deleteProjectMeta`
  at all, whenever `!snapshot.ok || !snapshot.configured`.
- **live-null-means-no-verdict**: a `live: null` result MUST be read by a caller
  as "this read proves nothing about what is gone," never as "nothing is gone" —
  it is the signal that stops a caller narrowing its own owned-target set off a
  partial or unconfigured read.
- **eviction-diffs-live-set-against-stored-names**: when the eviction path does
  run (`snapshot.ok && snapshot.configured`), `syncVercelProjectMeta` MUST build
  `live` as the set of `meta[].projectName` values, read the currently stored
  Vercel names via `storage.deploy.listProjectMetaNames('vercel')`, and compute
  `pruned` as every stored name absent from `live`.
- **delete-only-when-pruned-nonempty**: `syncVercelProjectMeta` MUST call
  `storage.deploy.deleteProjectMeta('vercel', pruned)` only when
  `pruned.length > 0`, and MUST NOT call it with an empty name list.
- **empty-meta-with-ok-and-configured-evicts-everything**: an authenticated,
  complete snapshot with `meta: []` MUST evict every currently stored Vercel
  project, because `configured` — not `meta.length > 0` — is what proves the
  read is trustworthy; the source's own reasoning is that "an empty list from an
  authenticated, complete read is the truth, not a failure," covering the case
  where a real account has had its last project deleted.
- **result-returns-remaining-live-set**: on the eviction path,
  `syncVercelProjectMeta` MUST return the same `live` set it computed for the
  diff, not `null`, so a caller can narrow its own owned-target list from this
  call's verdict instead of re-deriving the same predicate itself.
- **configured-gate-not-inferred-from-meta-length**: `refreshVercelProjectMeta`
  MUST derive `configured` from `!!env.VERCEL_API_TOKEN` alone, never from
  whether `meta` came back non-empty, so that an account whose last project was
  deleted is still `configured: true` and still eligible for eviction.
- **fail-closed-no-network-call-without-token**: `refreshVercelProjectMeta` MUST
  return `{ ok: false, configured: false, pruned: [] }` without calling
  `fetchVercelProductionStates` at all when `!env.VERCEL_API_TOKEN` — zero
  network attempt, not a call that is made and then ignored.
- **meta-only-fetch-mode**: `refreshVercelProjectMeta` MUST call
  `fetchVercelProductionStates` with `metaOnly: true` whenever a token is
  configured, so the request-path read of "which projects exist" asks for the
  shallowest deployment window the Vercel API allows rather than the monitor
  cycle's full history depth.
- **refresh-result-ok-mirrors-fetch-ok**: `refreshVercelProjectMeta` MUST set its
  returned `ok` to the fetch result's own `ok` (`res.ok`), and MUST set `pruned`
  to whatever `syncVercelProjectMeta` computed from that fetch's snapshot.
- **config-resolution-delegated-to-provider-conn**: `refreshVercelProjectMetaFromConfig`
  MUST resolve the Vercel token and team id by calling `providerConn(storage,
  config)` and reading `conn.vercel.token` / `conn.vercel.teamId`; the actual
  lookup that `providerConn` performs is against `config.secrets` (a
  `Readonly<Record<string, string | undefined>>` by-name lookup), not against
  `config.credentials` (the fixed named tuple) as this function's own doc
  comment states — the code's real behavior, traced through `provider-conn.ts`,
  is the by-name `secrets` lookup, and that is the contract this recipe
  documents.
- **concurrent-invocation-not-guarded**: The reconcile is performed as three separate storage calls (the upsert, the name listing and the conditional delete) with no transaction or lock spanning them. Two overlapping invocations can interleave those steps and evict a name another call's upsert had just restored, or compute a prune list against a set another call is mid-upsert on; the status server calls this function from more than one independent site with no coordination.

