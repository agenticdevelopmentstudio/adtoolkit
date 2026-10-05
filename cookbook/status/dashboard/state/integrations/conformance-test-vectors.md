
There is no test file for the source directly. Companion component tests mock the module out with a fixed no-data, not-loading result, so the vectors below come from the source. They assume a shared cache with retries disabled and a stubbed transport.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-integrations-001 | always-enabled, request-path, request-init, client-source | Use Integrations with the default client; the stub returns `200` and `{"generatedAt":"2026-09-24T00:00:00Z","overall":"ok","checks":[]}` | Exactly one request, to `/api/integrations`, with no added options; `data` deep-equals the body |
| use-integrations-002 | client-source, request-path | API base path `/proxy`, use Integrations | The requested URL is `/proxy/integrations` |
| use-integrations-003 | non-ok-error, error-detail-dropped | The stub returns `502` with body `{"error":"upstream down"}` | `isError` is true; error message is exactly `status 502`; the body text is not in the message |
| use-integrations-004 | parse-failure | The stub returns `200` with body `not json` | `isError` is true; error is the parse failure from reading the body |
| use-integrations-005 | network-failure | The stub fails with a network error | `isError` is true; error is that same failure |
| use-integrations-006 | query-key, single-threaded-ordering | Two consumers each use Integrations under one shared cache | One request in total; both results have the same `data` |
| use-integrations-007 | refetch-on-focus | After a successful fetch with a zero freshness window, report the runtime regaining focus | A second request to `/api/integrations` is made |
| use-integrations-008 | shared-interval-refresh | Use Integrations alongside Refresh All (interval 1000 ms) with simulated time; advance 1000 ms | A second request to `/api/integrations` is made |
| use-integrations-009 | raw-fetch-not-json-helper | Inspect the request | Integrations adds no `Content-Type` header |
| use-integrations-010 | integration-check-optional-fields, success-body | The stub returns a check carrying `"missingEnv":["CLOUDFLARE_ACCOUNT_ID"],"unreachable":true,"correlated":true` | `data.checks[0]` keeps all three fields exactly as sent |
| use-integrations-011 | client-only | Load Integration Self-Check in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

