
`syncVercelProjectMeta` calls `console.log('[project-meta] evicted N deleted
Vercel project(s): ...')` exactly once per invocation, and only when
`pruned.length > 0` — no log line is emitted for an eviction attempt that finds
nothing to prune, for the no-eviction-attempted branches, or for the upsert
itself. No other logger or `console.*` call appears anywhere in this file.

