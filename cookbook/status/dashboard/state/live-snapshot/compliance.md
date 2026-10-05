
| Check | Status | Category |
|-------|--------|----------|
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | best-practices |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | passed | reliability |
| [idempotent-operations](agenticdevelopercookbook://compliance/reliability#idempotent-operations) | passed | reliability |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | partial | reliability |
| [resource-efficiency](agenticdevelopercookbook://compliance/performance#resource-efficiency) | passed | performance |

**Unit Test Coverage**: The tests cover `isSameSnapshot`, stream open and snapshot ingestion, the schedule frame, the manual-check spinner and its long backstop, the absence of an immediate re-read after a started check, and the `CLOSED` versus `CONNECTING` reconnect paths. Nothing asserts `liveError`, `offline`, `disconnected`, `blind`, overlapping checks, or two-client isolation.

**Separation of Concerns**: Transport sits behind `StatusApiClient`, caching behind React Query, and board derivation in `useBoard`. This module only moves snapshots and connection state.

**Explicit Error Handling**: Poll failures are recorded in `liveError` and surfaced. Malformed frames are dropped by declared design, and a failed manual check is folded into the not-started path with no signal to the caller.

**Graceful Degradation and Error Recovery**: A dead stream falls back to the poll with an immediate re-read, and a permanently closed stream is recreated every 3 s while referenced.

**Idempotent Operations**: `ingestOnce` folds re-delivered and duplicated frames exactly once across all mounted hooks and StrictMode double effects.

**Timeout Handling**: The check spinner is bounded by `CHECK_SAFETY_MS`, but neither request has a client timeout.

**Resource Efficiency**: One ref-counted connection per client, the poll gated off while streaming, and `reconnect` kept as a GET so retry loops never trigger a provider fan-out.

