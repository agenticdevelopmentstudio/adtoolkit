
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | passed | Reliability |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | Security |
| [no-pii-in-logs](agenticdevelopercookbook://compliance/privacy-and-data#no-pii-in-logs) | passed | Privacy and Data |

`separation-of-concerns` passes: each of the 13 store files owns exactly one
port's implementation against the driver, `owned-deploys.ts` owns exactly
one shared predicate, and none of the 14 files contains a route handler,
an HTTP concern, or a monitor-cycle scheduling decision — those live in
sibling modules that import this layer rather than being imported by it.
`unit-test-coverage` passes: the sibling `test/` suite exercises the
last-admin guard (`last-admin-guard.int.test.ts`), the upsert ordering and
minimum/COALESCE rules (`upsert-deployments.test.ts`,
`deploy-upsert-guard.test.ts`), the errors-reconciliation sweep
(`telemetry-errors-store.int.test.ts`), the device-authorization flow
(`device-flow.int.test.ts`), and the group/site/endpoint delete cascade
(`site-delete-purge.int.test.ts`) — each targeting exactly the atomic-guard
or reconciliation behavior that would be easiest to silently regress.
`explicit-error-handling` passes: every tolerated failure path in this
layer (the not-yet-migrated-table checks, the fail-soft checkpoint and
snapshot, the orphan-reconcile catch) matches a specific, narrow error
signature or is logged before being swallowed — none of the 14 files
contains a bare catch that discards an error with no signal at all.
`data-integrity` passes: every atomic guard in this recipe (last-admin,
device-grant single-use, TOCTOU-safe conditional deletes, webhook-vs-poll
ordering) is expressed as a single SQL statement rather than a
read-then-write pair, so the invariant it protects cannot be violated by
an interleaving of two concurrent calls. `idempotent-operations` passes:
`upsertDeployments`, `errorsStore.save`, `recordVercelProdStates`, and
every peer-snapshot/project-meta upsert are all safe to call repeatedly
with the same or updated input, converging on the latest state rather
than accumulating duplicates. `state-recovery` passes: `peer-store.ts`'s
snapshot table and `observation-store.ts`'s platform-health state exist
specifically so a restarted process recovers the fleet's last-known state
from disk rather than starting blank, mirroring the same pattern the
`status-server-libsql` recipe documents for the schema those tables
belong to. `secure-storage` passes: `auth-store.ts`, `token-store.ts`, and
`device-store.ts` persist a hash, never a raw secret, with exactly one
documented, time-boxed, single-use exception (`tokenRaw` in
`device-store.ts`, cleared atomically by `consumeApproved`).
`no-pii-in-logs` passes: every logged message identified in this recipe's
Logging section names a deployment id, a step name, a file path, or a
row count — never an email, a password hash, a session/API/device-code
hash, or a `tokenRaw` value.

