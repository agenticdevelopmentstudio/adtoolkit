
| Check | Status | Category |
|-------|--------|----------|
| [server-side-authorization](agenticdevelopercookbook://compliance/security#server-side-authorization) | passed | Security |
| [secure-log-output](agenticdevelopercookbook://compliance/security#secure-log-output) | passed | Security |
| [rate-limit-handling](agenticdevelopercookbook://compliance/access-patterns#rate-limit-handling) | passed | Access Patterns |
| [error-response-handling](agenticdevelopercookbook://compliance/access-patterns#error-response-handling) | passed | Access Patterns |
| [separation-of-concerns](agenticdevelopercookbook://compliance/best-practices#separation-of-concerns) | passed | Best Practices |
| [unit-test-coverage](agenticdevelopercookbook://compliance/best-practices#unit-test-coverage) | passed | Best Practices |
| [explicit-error-handling](agenticdevelopercookbook://compliance/best-practices#explicit-error-handling) | partial | Best Practices |
| [data-minimization](agenticdevelopercookbook://compliance/privacy-and-data#data-minimization) | passed | Privacy and Data |

`server-side-authorization` passes: `tier` is set exclusively from the
injected `AuthGate`'s resolution, and `requireAdmin` compares only that
server-set context value — no header, cookie, or query parameter is ever
trusted as a tier claim. `secure-log-output` passes: the one log statement
in these two files (the hard-cap drop) carries only a count and a fixed
threshold, never a key, IP, or credential; `auth.ts` logs nothing at all.
`rate-limit-handling` passes: the pre-auth credential routes are capped
per-key with a fixed window, a defined `429` response, and a computed
`Retry-After` header a client can act on. `error-response-handling` passes:
every rejection in these two files resolves to one specific, distinguishable
status (`401`, `403`, `429`) with a JSON body, never a generic failure or a
silent pass-through. `separation-of-concerns` passes: `auth.ts` only
translates a gate's resolution into HTTP and never resolves a credential
itself; `rate-limit.ts` only counts requests and knows nothing about
authentication. `unit-test-coverage` passes: `auth-gate.test.ts` exercises
`requireAuth`'s 200/401 split directly, `rate-limit.int.test.ts` exercises
the limiter's cap, recovery, and IP-spoofing resistance, and
`auth.int.test.ts`/`api-tokens.int.test.ts` exercise `requireAdmin`'s 403
path end-to-end. `explicit-error-handling` is `partial`: every rejection
these two files themselves produce is explicit, but `requireAuth` does not
wrap its `await gate.authenticate(c.req)` call in a `try`/`catch`, so a
rejected gate promise (a dependency failure, not an unauthenticated caller)
propagates uncaught rather than being mapped to a specific status by this
file — a deliberate scope boundary per the `AuthGate` contract (see Edge
Cases), but still a case where this file itself does not produce the final
error response. `data-minimization` passes: `rate-limit.ts` retains only
the derived IP key and a count/reset timestamp per bucket — no request
body, path, or other request data is captured by the limiter — and `bearer`
returns a substring of one header with no further extraction.

