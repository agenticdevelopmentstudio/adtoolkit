
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| auth-client-server-001 | backend-url-explicit-override | Backend-URL resolution given `{ API_BACKEND_URL: 'https://custom.example', NODE_ENV: 'production' }` | Returns `'https://custom.example'` |
| auth-client-server-002 | backend-url-empty-override-ignored | Backend-URL resolution given `{ API_BACKEND_URL: '', NODE_ENV: 'production' }` | Returns `'https://api.agenticdeveloperhub.com'` (empty string is falsy) — derived directly from the truthiness check; no dedicated test exists |
| auth-client-server-003 | backend-url-production-default | Backend-URL resolution given `{ NODE_ENV: 'production' }` | Returns `'https://api.agenticdeveloperhub.com'` |
| auth-client-server-004 | backend-url-development-default | Backend-URL resolution given `{ NODE_ENV: 'development' }` | Returns `'http://localhost:3000'` |
| auth-client-server-005 | backend-url-development-default | Backend-URL resolution given `{}` | Returns `'http://localhost:3000'` |
| auth-client-server-006 | api-prefix-strips-namespace | The backend forwarder called for the `api` prefix with path segments `['users', '42']`, against a resolved backend of `'http://localhost:3000'` | Outbound target path is `'http://localhost:3000/users/42'` — no `api/` segment inserted |
| auth-client-server-007 | auth-prefix-preserved | The backend forwarder called for the `auth` prefix with path segment `['login']` | Outbound target path is `'http://localhost:3000/auth/login'` |
| auth-client-server-008 | path-segments-joined-and-appended | The backend forwarder called with path segments `['a', 'b', 'c']` | Target path segment is `'a/b/c'` |
| auth-client-server-009 | query-string-forwarded | Inbound request URL `'https://site.example/api/foo?x=1&y=2'`; the backend forwarder called for the `api` prefix with path segment `['foo']` | Outbound target URL ends with `'?x=1&y=2'` |
| auth-client-server-010 | host-header-removed, content-length-header-removed | Inbound request carrying `Host: site.example` and `Content-Length: 42` | Forwarded headers have no `host` entry and no `content-length` entry |
| auth-client-server-011 | accept-encoding-forced-identity | Inbound `Accept-Encoding: gzip, deflate, br, zstd` | Forwarded `accept-encoding` is `'identity'` |
| auth-client-server-012 | accept-encoding-forced-identity | Inbound `Accept-Encoding: gzip` only | Forwarded `accept-encoding` is still `'identity'` |
| auth-client-server-013 | redirect-not-followed | Backend responds `302` with `Set-Cookie: session=abc` | The backend forwarder's returned response is `302` with the same `Set-Cookie` header — the outbound request was issued with redirect-following disabled and never followed it itself |
| auth-client-server-014 | body-forwarded-for-mutating-methods | The backend forwarder called with a `POST` request whose body is `'{"code":"x"}'` | Outbound body is the exact raw bytes of `'{"code":"x"}'` |
| auth-client-server-015 | no-body-for-get-or-head | The backend forwarder called with a `GET` request | Outbound body is absent |
| auth-client-server-016 | response-returned-verbatim | Backend responds `200` with JSON body `{"ok":true}` | The backend forwarder resolves to that exact response — same status and body bytes, nothing rewritten |
| auth-client-server-017 | five-methods-generated | The handler factory called for the `api` prefix | Returned object has exactly the keys `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, each a function |
| auth-client-server-018 | identical-behavior-across-methods | Invoke the `PUT` and `DELETE` handlers the handler factory returns for the `auth` prefix, with the same request/context | Both call the backend forwarder for the `auth` prefix identically, because both keys reference the same underlying handler |
| auth-client-server-019 | params-awaited-before-forwarding | The route's path parameters resolve (after a microtask) to `{ path: ['x'] }` | The handler awaits them before calling the backend forwarder, so the forwarder never receives an unresolved deferred value in place of the path |
| auth-client-server-020 | credentials-forwarded-opaquely | Inbound request carrying `Cookie: session=abc` and `Authorization: Bearer tok` | Both headers appear unchanged in the outbound headers; only `host` and `content-length` are removed |
| auth-client-server-021 | backend-is-sole-authenticator | Backend responds `401` with body `{"error":"invalid_token"}` | The backend forwarder returns that exact `401` response unchanged; no status-code check runs before or after the call |
| auth-client-server-022 | no-token-lifetime-authority | Any call into this module | No code path reads, decodes, stores, or sets an expiry on a token/cookie value; the only data inspected are header names and the path/prefix routing parameters |

