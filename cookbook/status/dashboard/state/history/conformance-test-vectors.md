
No test file exists for the source directly; these vectors are derived from the source. They assume a shared cache with retries disabled and a stubbed transport.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-history-001 | disabled-without-slug, query-key | History with no slug | No request is made; the result's status is `"pending"` with fetch status `"idle"`; `data` is not yet available |
| use-history-002 | disabled-without-slug | History with an empty-string slug | No request is made |
| use-history-003 | enabled-with-slug, request-path, fixed-window, request-init, client-source | History with slug `"api"` and the default client; stub returns `200` and `{"service":"api","hours":24,"checks":[]}` | Exactly one request to `/api/history?service=api&hours=24` with no added options; `data` deep-equals the body |
| use-history-004 | slug-encoding | History with slug `"a b/c&d"` | The requested path is `/api/history?service=a%20b%2Fc%26d&hours=24` |
| use-history-005 | client-source, request-path | API base path `/proxy`, History with slug `"web"` | The requested URL is `/proxy/history?service=web&hours=24` |
| use-history-006 | non-ok-error, error-detail-dropped | History with slug `"api"`; stub returns `503` with body `{"error":"down for maintenance"}` | `isError` is true; error message is exactly `history 503`; the body text does not appear in the message |
| use-history-007 | parse-failure | History with slug `"api"`; stub returns `200` with body `not json` | `isError` is true; error is the parse failure from reading the body |
| use-history-008 | network-failure | History with slug `"api"`; stub fails with a network error | `isError` is true; error is that same failure |
| use-history-009 | query-key | Use History with slug `"a"`, then with slug `"b"` | Two requests, one per slug; returning to `"a"` within the cache's lifetime serves the cached `"a"` data |
| use-history-010 | raw-fetch-not-json-helper | History with slug `"api"`; inspect the request | No `Content-Type` header is added by History |
| use-history-011 | client-only | Load Health Check History in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

