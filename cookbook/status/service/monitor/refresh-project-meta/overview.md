
`refresh-project-meta.ts` keeps the `deploy_project_meta` table's Vercel rows in
sync with a fetched account snapshot. Its own module comment states the problem
it fixes directly: the table was previously upsert-only, so a project deleted at
Vercel "was enumerated forever," Auto Configure "kept being offered" it, and its
"dead deploy target reopened an unclearable Problem." This file makes the table a
mirror of the account by pairing every upsert with a matching eviction, and is
"deliberately the only writer, so the prune can never drift from the upsert."

It exports three functions along three narrowing layers: `syncVercelProjectMeta`
(the pure-ish reconcile against storage, given an already-fetched snapshot),
`refreshVercelProjectMeta` (adds the fetch, gated on a raw env token), and
`refreshVercelProjectMetaFromConfig` (adds resolving that token from a
`StatusConfig`/`Storage` pair via `provider-conn.ts`). Only Vercel rows are ever
touched; Cloudflare, Railway, and Crunchy rows in the same table are polled live
elsewhere and are never upserted or pruned by this file.

