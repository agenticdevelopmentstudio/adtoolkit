
There is no dedicated test file for this concept; these vectors are derived from the source. They assume a shared cache context with retries disabled and a status API client provider with a stubbed fetch.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-response-history-001 | always-enabled, request-path, request-init, client-source, no-buckets-parameter | Response History with `hours` = 24, using the default client; stub returns `200` and `{"hours":24,"points":[120,null,95]}` | Exactly one fetch to `/api/response-history?hours=24` with no extra request options and no `buckets` parameter |
| use-response-history-002 | success-body, points-semantics, response-history-shape | Same as 001 | `data` deep-equals `{"hours":24,"points":[120,null,95]}`; the `null` stays in position 1 |
| use-response-history-003 | client-source, request-path | Status API client provider with base path `/proxy`; Response History with `hours` = 168 | The requested URL is `/proxy/response-history?hours=168` |
| use-response-history-004 | hours-interpolation | Response History with `hours` = 1.5 | The requested path is `/api/response-history?hours=1.5` |
| use-response-history-005 | non-ok-error, error-detail-dropped | Response History with `hours` = 24; stub returns `401` with body `{"error":"unauthorized"}` | `isError` is true; `error.message` is exactly `response-history 401`; the body text does not appear in the message |
| use-response-history-006 | parse-failure | Response History with `hours` = 24; stub returns `200` with body `not json` | `isError` is true; `error` is the parse error thrown while decoding the body |
| use-response-history-007 | network-failure | Response History with `hours` = 24; stub rejects with a network error | `isError` is true; `error` is that same network error |
| use-response-history-008 | polling-interval | Response History with `hours` = 24 and a controllable timer; first fetch succeeds | Advancing time by 60,000 ms triggers a second fetch to the same URL; advancing less than 60,000 ms does not |
| use-response-history-009 | query-key | Start using Response History with `hours` = 24, then switch to `hours` = 720 | Two fetches, one per window; returning to `24` within the cache's lifetime serves the cached 24-hour data |
| use-response-history-010 | raw-fetch-not-json-helper | Response History with `hours` = 24; inspect the request | No `Content-Type` header is added by Response History |
| use-response-history-011 | single-threaded-ordering | Two components both use Response History with `hours` = 24, sharing one cache context | One fetch is made; both receive the same `data` |
| use-response-history-012 | client-only | Load Response History in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

