
Vectors 001 to 004 come from the shared request function's own test assertions, exercised with an injected transport. The remaining vectors are derived from the source and assume a test cache and an injected API client.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-status-user-001 | ok-user-response, status-user-shape | `/auth/me` responds 200 `{ user: { email: "a@b.c", displayName: "A", role: "admin" } }` | Resolves to exactly that user object (test: "resolves the user from a definitive 200") |
| use-status-user-002 | ok-null-response | `/auth/me` responds 200 `{ user: null }` | Resolves to `null` (test: "resolves null from a definitive signed-out 200") |
| use-status-user-003 | non-ok-throws | `/auth/me` responds 500 `{}` | The request function rejects with an error matching `HTTP 500`; the result is not `null` (test: "THROWS on a 5xx") |
| use-status-user-004 | network-error-propagates | The transport rejects with a network-level error (`fetch failed`) | The request function rejects with an error matching `fetch failed` (test: "propagates a network failure") |
| use-status-user-005 | session-request, api-client-injection | Default client (base `/api`); render the state | Exactly one `GET` to `/api/auth/me` with no body |
| use-status-user-006 | user-projection, null-when-unknown | Render the state while the first request is still pending | Returns `null`; the return value has no loading-flag property |
| use-status-user-007 | keep-last-known-session | Cache holds user U; invalidate the key and make every retry answer 503 | The state keeps returning U through all 4 attempts and after the read enters its error state |
| use-status-user-008 | retry-count, null-when-unknown, no-error-exposure | Empty cache; every `/auth/me` call answers 502 | 4 requests in total; the state then returns `null` with no error exposed |
| use-status-user-009 | shared-cache-key, single-query-owner | Mount this state and the shared session state together with an empty cache | One request; both read the same user from the `status-auth-me` cache key |
| use-status-user-010 | stale-time | Session loaded at t=0; mount a second consumer at t=30,000 ms, then a third at t=61,000 ms | No request at 30,000 ms; one background refetch at 61,000 ms |
| use-status-user-011 | ok-null-response | `/auth/me` responds 200 `{}` | Resolves to `null` |
| use-status-user-012 | query-provider-precondition | Render the state with no shared cache provider available | Render throws a missing-client error |
| use-status-user-013 | body-not-validated | 200 `{ user: { email: "x@y.z", role: "superuser" } }` | Returns the object as sent, with `role` `"superuser"`; no error |
| use-status-user-014 | client-only | Load Status User State in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

