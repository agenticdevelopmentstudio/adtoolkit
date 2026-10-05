
The status state is the dashboard's read of the service health summary. It issues one `GET /status` request through an injected API client and caches the response — `{ overall, services, checkedAt }` — under the shared cache key `status`. The dashboard view is its consumer: it reads `data.services`, `data.checkedAt`, the loading flag and the error, and renders `Failed to load status — <error message>` when the read fails.

The one piece of logic this state adds over a plain request is error-reason extraction: the endpoint returns `{ error }` with the real reason (for example a database outage), and that is surfaced as the thrown message so the UI shows WHY, not `status 503`. The state returns the full underlying read result unchanged.

