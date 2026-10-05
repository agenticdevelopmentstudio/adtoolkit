
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-status-001 | query-key, request-path, success-ok | Default client; the transport resolves with status `200` and body `{ "overall": "operational", "services": [], "checkedAt": "2026-09-24T00:00:00Z" }` | One request to `/api/status`; `data` deep-equals the body; `error` is `null`; the read is cached under `status` |
| use-status-002 | error-body-read, error-detail-message | The transport resolves with status `503` and body `{ "error": "database unavailable" }` | Read fails; `error` is an error whose message is exactly `database unavailable` |
| use-status-003 | error-status-fallback | The transport resolves with status `503` and body `{}` | `error.message` is `status 503` |
| use-status-004 | error-status-fallback, error-parse-swallowed | The transport resolves with status `502` and a non-JSON body `Bad Gateway` | `error.message` is `status 502`; no JSON parsing error surfaces |
| use-status-005 | error-status-fallback | The transport resolves with status `500` and body `{ "error": "" }` | `error.message` is `status 500` |
| use-status-006 | error-nonstring-detail | The transport resolves with status `500` and body `{ "error": { "message": "x" } }` | `error.message` is `[object Object]` |
| use-status-007 | network-failure | The transport itself fails with a network-level error | `error` is that same failure, unchanged |
| use-status-008 | success-parse-failure | The transport resolves with status `200` and a non-JSON body `not json` | Read fails with the error produced by parsing the body as JSON; message does not start with `status ` |
| use-status-009 | client-injection, request-path | An overriding client configured with base path `/proxy`; the transport resolves with status `200` and a valid body | The request URL is `/proxy/status` |
| use-status-010 | shared-cache | Two consumers use the status state under one shared cache; the transport resolves after a delay | Exactly one request is made; both consumers receive the same `data` |
| use-status-011 | refetch-on-focus | The read is loaded and stale; the application regains focus | One additional request to `/status` is made |
| use-status-012 | error-message-only | The transport resolves with status `503` and body `{ "error": "db down" }` | `error` has no `status` or `body` property; only `message` is `db down` |
| use-status-013 | result-type | A consumer mock providing the result shape `{ isLoading: false, error: null, data: { overall: "operational", checkedAt, services: [one healthy service] } }` | The dashboard view reads `data.services` and `data.checkedAt` from the result without adaptation (the result is the raw read result) |
| use-status-014 | client-only | Load Status State in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

