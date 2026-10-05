
| Check | Status | Category |
|-------|--------|----------|
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | best-practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | partial | best-practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | passed | best-practices |
| [error-recovery](agenticdevelopercookbook://compliance/reliability#error-recovery) | passed | reliability |
| [graceful-degradation](agenticdevelopercookbook://compliance/reliability#graceful-degradation) | passed | reliability |
| [timeout-handling](agenticdevelopercookbook://compliance/reliability#timeout-handling) | failed | reliability |
| [secure-storage](agenticdevelopercookbook://compliance/security#secure-storage) | passed | security |

**separation-of-concerns** passes. The adapter only reshapes the result, and fetch and cache semantics live in one query function in `header-auth.ts`.

**unit-test-coverage** is partial. `header-auth.test.ts` covers `fetchStatusUser` for 200 with a user, 200 with null, 500 and a network failure. Nothing tests the adapter itself or the query options (retry, stale time, keeping cached data).

**explicit-error-handling** passes. Non-OK responses throw with the HTTP status, and network errors propagate instead of turning into a sign-out. The adapter's choice not to expose the error is a documented projection, not a swallowed failure.

**error-recovery** and **graceful-degradation** pass. Transient failures retry 3 times with backoff while the last-known session keeps being shown.

**timeout-handling** fails. The request has no timeout or abort signal, so a hung `/auth/me` stays pending indefinitely.

**secure-storage** passes. The credential is an httpOnly cookie that the client never reads, and the user record is held only in memory.

