
- **Data collected**: cluster identity and health metadata — `id`, `name`, `state`, `is_suspended`, `environment`, and `created_at` — read from Crunchy Bridge's `/clusters` response. This is infrastructure metadata about the team's own database clusters, not end-user personal data.
- **Storage**: this file writes nothing to persistent storage; it only fetches and maps. Persisting the resulting deploy rows is a job external to this file.
- **Transmission**: `env.CRUNCHY_API_TOKEN` is sent only as an `Authorization: Bearer` header on the outbound request, never in a query string or request body. The transport origin is hardcoded to `https://`, per **https-transport** — this file, unlike its sibling Cloudflare/GlitchTip/PostHog fetchers, never accepts a caller-supplied host and so cannot be misconfigured onto a non-TLS origin.
- **Retention**: this file holds the token and every fetched cluster field only for the duration of one `fetchCrunchyClusters` call; there is no in-memory cache of any kind.

