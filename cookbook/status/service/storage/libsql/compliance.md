
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | Best Practices |
| [data-integrity](agenticdevelopercookbook://compliance/reliability#data-integrity) | passed | Reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | Reliability |
| [state-recovery](agenticdevelopercookbook://compliance/reliability#state-recovery) | passed | Reliability |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | partial | Reliability |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | Security |

`separation-of-concerns` passes: `client.ts` owns the connection lifecycle
(open, tune, checkpoint, migrate) and `schema.ts` owns only the table
shapes; neither file contains a query, a route, or a probe — those live in
sibling modules (`db/config.ts`, `monitor/`, the Hono routes) that import
these two files rather than being imported by them. `unit-test-coverage`
passes: the sibling `test/` suite exercises `migrateDb`'s idempotency
(`migrate-idempotent.int.test.ts`) and pins every shipped migration's hash
(`migrations-immutable.test.ts`); the schema's own constraints
(unique indexes, foreign keys) are exercised indirectly by the integration
tests of the modules that write through them. `explicit-error-handling`
passes: `openLibsql`'s one validated input throws synchronously with a
specific message, and every unique-index/foreign-key violation propagates
as a rejected promise from the underlying driver — neither file wraps or
swallows a failure anywhere. `data-integrity` passes: seven unique indexes
(`uniq_metrics_service_hour`, `uniq_open_issue_per_target`,
`uniq_site_group_slug`, `uniq_site_group_site_slug`, `uniq_peer_base_url`,
`uniq_error_issue`, `uniq_user_email`/`uniq_user_github`,
`uniq_session_token`, `uniq_api_token_hash`, `uniq_device_code`/`uniq_user_code`)
and six foreign keys enforce the schema's own invariants at the database
layer rather than trusting callers to. `idempotent-operations` passes:
`migrateDb` is explicitly designed and tested to be safe to call
repeatedly (migrate-idempotent), and `tuneDbForConcurrency`'s pragmas are
documented as safe to re-apply. `state-recovery` passes: `peerSnapshots`
and `platformHealthState` exist specifically so a restarted, stateless
serverless process recovers its last-known fleet/platform state from disk
rather than starting blank, per their table comments. `timeout-handling`
is `partial`: `busy_timeout=5000` bounds how long a second writer waits on
`SQLITE_BUSY` for an embedded file, but neither file applies any
timeout to a remote libsql/Turso connection's network calls — that is left
entirely to the `@libsql/client` driver `drizzle()` wraps, external to
these two files. `secure-storage` passes: every credential-shaped column
in `sessions`/`apiTokens`/`deviceAuthorizations` stores a sha256 hash, with
`tokenRaw` as the one explicitly time-boxed, single-use, never-listed
exception documented in its own column comment.

