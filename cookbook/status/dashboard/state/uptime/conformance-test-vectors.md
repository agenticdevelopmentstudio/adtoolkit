
No dedicated test exists for this state; the consuming views' tests mock it out entirely (returning a result with `data: undefined, isLoading: false`), so these vectors are derived from the source. Wrap the state in a shared cache provider configured with retries disabled and an overriding client with a stubbed transport.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| use-uptime-001 | days-default, always-enabled, request-path, request-init, client-source | This state called with no argument, using the default client; stub returns `200` and `{"services":[],"days":90}` | Exactly one fetch to `/api/uptime?days=90` with no extra request options |
| use-uptime-002 | success-body, uptime-response-shape, uptime-service-shape, uptime-day-shape, pass-through | This state called with `90`; stub returns `200` and `{"services":[{"slug":"b","name":"B","uptimePercent":null,"totalChecks":0,"daily":[]},{"slug":"a","name":"A","uptimePercent":99.5,"totalChecks":200,"daily":[{"day":"2026-09-23","status":"degraded","uptimePercent":99}]}],"days":90}` | `data` deep-equals the body; service `b` stays first and its `null` percentage is unchanged |
| use-uptime-003 | client-source, request-path | An overriding client with base path `/proxy`; this state called with `30` | The requested URL is `/proxy/uptime?days=30` |
| use-uptime-004 | days-interpolation | This state called with `1.5` | The requested path is `/api/uptime?days=1.5` |
| use-uptime-005 | non-ok-error, error-detail-dropped | This state called with `90`; stub returns `401` with body `{"error":"unauthorized"}` | `isError` is true; `error.message` is exactly `uptime 401`; the body text does not appear in the message |
| use-uptime-006 | parse-failure | This state called with `90`; stub returns `200` with body `not json` | `isError` is true; `error` is the JSON parse error thrown while parsing the body |
| use-uptime-007 | network-failure | This state called with `90`; stub rejects with a network-level error | `isError` is true; `error` is that same failure |
| use-uptime-008 | no-polling | This state called with `90`, with fake timers; first fetch succeeds; the application keeps focus | Advancing time by 600,000 ms triggers no second fetch |
| use-uptime-009 | query-key | Render this state with `90`, then rerender with `30` | Two fetches, one per window; returning to `90` within the cache's lifetime serves the cached 90-day data |
| use-uptime-010 | raw-fetch-not-json-helper | This state called with `90`; inspect the request | No `Content-Type` header is added by the state |
| use-uptime-011 | single-threaded-ordering | Two consumers both use this state with `90` under one shared cache | One fetch is made; both receive the same `data` |
| use-uptime-012 | return-value | This state called with `90`, before the stub resolves | The result has `isLoading` true and `data` undefined, and exposes no keys beyond the read result's own |
| use-uptime-013 | client-only | Load Uptime State in a server-only rendering context | It is unavailable there: the module is marked for client execution only |

