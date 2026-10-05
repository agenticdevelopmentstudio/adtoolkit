
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | partial | Reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | Reliability |

`unit-test-coverage` passes: `test/refresh-project-meta.int.test.ts` exercises
both `syncVercelProjectMeta` (five cases: full eviction, chunked upsert/prune,
partial-read no-eviction, unconfigured no-eviction, last-project-deleted
eviction) and `refreshVercelProjectMeta` (fetch-then-evict, and no-token
fail-closed) directly against a real storage instance, covering every branch
this recipe documents. `separation-of-concerns` passes: this file owns exactly
one concern — reconciling `deploy_project_meta`'s Vercel rows against a
snapshot — and delegates fetching to `fetchVercelProductionStates` and token
resolution to `providerConn`, reimplementing neither. `explicit-error-handling`
passes on its narrow "MUST NOT silently swallow" bar: none of the three
functions contains a `try`/`catch`, so every storage or fetch rejection
propagates intact to the caller rather than being caught and discarded.
`idempotent-operations` passes: calling `syncVercelProjectMeta` repeatedly with
the same snapshot converges to, and stays at, the same stored row set — the
upsert's `onConflictDoUpdate` and the eviction's set-diff are both naturally
idempotent per the source's own chunking implementation in `deploy-store.ts`.
`data-integrity` is rated partial, not failed, because within a single,
non-overlapping call the three-step reconcile is internally consistent (the
integration tests confirm the intended upsert/evict outcome every time); the
open question on concurrent-invocation-not-guarded is what keeps it from a full
pass — nothing in this file wraps the upsert, the read-back, and the delete in
one transaction or lock, so two overlapping invocations (this codebase's actual
callers include a periodic monitor cycle and a request-path cache, coordinated
with each other in neither file) could interleave and produce an incorrect
prune list or a lost upsert. `graceful-degradation` passes: a partial
(`ok: false`) or unconfigured read degrades to "upsert what came back (if any),
evict nothing" rather than either crashing or wiping the table on incomplete
information, which is exactly the behavior `no-eviction-attempt-when-not-ok-or-not-configured`
and the partial-read test vector pin.

