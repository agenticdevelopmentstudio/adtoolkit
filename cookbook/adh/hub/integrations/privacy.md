
- **Data collected**: this module originates no analytics of its own. It transports the provider
  catalog (no end-user data), ecosystem provider configs (OAuth client credentials or a GitHub App's
  app id/private key, secret-masked to `hasSecret` — except the deliverability webhook secret, which is
  passed through unredacted, see webhook-secret-visibility-after-mint), and connections (already
  redacted by the backend before this client ever sees them).
- **Storage**: none. This client is a stateless per-call request builder (no-client-side-cache,
  stateless-module); it holds nothing in memory or on disk beyond the lifetime of a single call.
- **Transmission**: every call carries a bearer credential attached by the shared authenticated-request
  helper (session-refresh-waterfall), not by this module; a save/create/update/connect call also
  transmits whatever client secret, API key, app password, or authorization code the caller supplies,
  over whatever transport the deployment provides — this module configures no TLS or transport-level
  behavior itself.
- **Retention**: none of the secret material this module handles is retained by this module after the
  response it produced is returned to the caller; retention of the underlying credential is a backend
  concern outside this component's own source.

