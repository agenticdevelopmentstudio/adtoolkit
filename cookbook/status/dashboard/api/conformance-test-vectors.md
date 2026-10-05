
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| status-web-api-001 | json-204-empty | A JSON request whose underlying response resolves as successful with status `204` | resolves to nothing; the body is never parsed |
| status-web-api-002 | json-ok-body | A JSON request whose underlying response resolves as successful with status `200` and body `{a: 1}` | resolves `{a: 1}` |
| status-web-api-003 | json-error-message, json-error-detail, site-crud | Update a site's name; the underlying response resolves as unsuccessful with status `404` and JSON body `{"error": "not found"}` | rejects with an error reading `PATCH /api/config/sites/x → 404 — not found` |
| status-web-api-004 | json-error-detail, peer-crud-routes | Create a peer; the underlying response resolves as unsuccessful with status `500` and a body that fails to parse as JSON | rejects with an error reading `POST /api/config/peers → 500` — no ` — ` suffix |
| status-web-api-005 | url-join | base path `/api`, path `/config/peers` | the joined URL is `/api/config/peers` |
| status-web-api-006 | event-stream-target | default client, path `/live/stream` | the open-event-stream operation opens a Server-Sent-Events connection at `/api/live/stream` |
| status-web-api-007 | (n/a — mapper passthrough, traced to the monitoring-configuration client's test file) | Group mapper given a row with an id, slug, name, and a 14-day retention | returns the same fields unchanged |
| status-web-api-008 | site-group-rename (traced to the monitoring-configuration client's test file) | Site mapper given a row whose group-identifier field is `"g1"` | the mapped view's `groupId` is `"g1"` |
| status-web-api-009 | endpoint-optional-field-defaults (traced to the monitoring-configuration client's test file) | Endpoint mapper given a row with `environment` absent | mapped `environment` is `null` |
| status-web-api-010 | endpoint-dns-defaults (traced to the monitoring-configuration client's test file) | Endpoint mapper given a row with all three DNS-check fields absent | all three default to `true` |
| status-web-api-011 | endpoint-dns-defaults (traced to the monitoring-configuration client's test file) | Endpoint mapper given a row with `dnsCheckCname: false` and the other two absent | `dnsCheckCname` stays `false`, `dnsCheckA` defaults to `true` |
| status-web-api-012 | peer-token-write-semantics, peer-write-passthrough | Update a peer's label only, without touching `token` | the serialized request body carries only the label field — no `token` key present at all |
| status-web-api-013 | peer-token-write-semantics | Update a peer with `token: null` | the serialized request body includes `"token": null` |
| status-web-api-014 | ignore-project-fanout | Mark two projects ignored in one call | exactly two `POST /config/ignored-projects` requests are issued, concurrently rather than sequentially |
| status-web-api-015 | unignore-project-id | Un-ignore a project identified by platform `vercel` and name `my/app` | request path is `DELETE /config/ignored-projects/vercel%7Cmy%2Fapp` |

