
Traced to the two source implementations; no test exercises either source directly (the only telemetry test covers the cache).

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sources-001 | live-endpoint, api-injection, get-only-requests | The live source's `get`, given an injected client whose request operation is a fake recording calls | Exactly one call: a request to `/telemetry` with no extra options |
| sources-002 | live-passthrough | `/telemetry` returns 200 with body `{"generatedAt":"2026-09-24T00:00:00Z","errors":[],"analytics":[]}` | Resolves to that object, `generatedAt` equal to `"2026-09-24T00:00:00Z"` |
| sources-003 | live-status-check, error-propagation | `/telemetry` returns 503 | Rejects with an error whose message is `telemetry 503`; body not read |
| sources-004 | network-rejection | The client's request rejects with a network-level error | The live source's `get` rejects with that same error |
| sources-005 | json-parse-rejection | `/telemetry` returns 200 with body `not json` | Rejects with the error thrown while parsing the body as JSON |
| sources-006 | turso-endpoints, turso-parallel | The persisted source's `get`, given a client whose request operation returns promises that stay pending | Both `/errors` and `/analytics` requests are issued before either resolves |
| sources-007 | turso-errors-projection, turso-analytics-projection, turso-snapshot-keys | `/errors` 200 `{"errors":[E],"extra":1}`; `/analytics` 200 `{"metrics":[M]}` | Resolves to `{ generatedAt, errors: [E], analytics: [M] }` with no `extra` or `metrics` key |
| sources-008 | turso-generated-at | Clock fixed at `2026-09-24T12:00:00.000Z`; both endpoints 200 | `generatedAt === "2026-09-24T12:00:00.000Z"` |
| sources-009 | turso-errors-status | `/errors` 500, `/analytics` 200 | Rejects with an error whose message is `errors 500` |
| sources-010 | turso-analytics-status | `/errors` 200, `/analytics` 404 | Rejects with an error whose message is `analytics 404` |
| sources-011 | turso-status-precedence | `/errors` 502, `/analytics` 503 | Rejects with an error whose message is `errors 502` |
| sources-012 | turso-network-rejection-order | The `/analytics` request rejects with a network-level error; the `/errors` request is still pending | Rejects with that same error; no status message produced |
| sources-013 | turso-body-order | `/errors` 200 but invalid JSON body, `/analytics` 200 with valid body | Rejects with the JSON-parse error from the `/errors` body; `/analytics` body not parsed |
| sources-014 | stateless | Call the live source's `get` twice | Two separate `/telemetry` requests; two distinct result objects |
| sources-015 | no-retry | `/telemetry` returns 500 once | Exactly one request made; rejects `telemetry 500` |
| sources-016 | default-source, interchangeable | Read the active exported source from the composition root | It is identical to the live source |

