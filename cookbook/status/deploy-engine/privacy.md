
- **Data collected**: Vercel, Railway, and Cloudflare API tokens (`token` /
  `conn.token` parameters) and, for Cloudflare, an account id. These are
  credentials supplied by the caller, not collected from an end user; no
  other personal data passes through any given source.
- **Storage**: No given source persists a token to disk or a database. One
  exception is process-lifetime, in-memory: Cloudflare's
  `discoveredAccountByToken` (in `providers/cloudflare.ts`) is a `Map` keyed
  by the raw token string, holding it for the life of the process once a
  successful single-account discovery has occurred (see the Design
  Decisions entry below); it is never written to persistent storage and is
  cleared only by `_resetCfAccountCache` (a test hook) or process exit.
- **Transmission**: Every provider call sends the token as an
  `Authorization: Bearer <token>` header over the provider's HTTPS endpoint
  (`api.cloudflare.com`, `backboard.railway.app`, `api.vercel.com`); no
  given source constructs a non-HTTPS URL or places a token in a query
  string or request body.
- **Retention**: No given source implements token revocation, rotation, or
  an expiry check; a token is used until the caller stops supplying it or
  the provider itself rejects it. This is an absent feature, not a marker —
  see Edge Cases and the `secure-storage`/`token-lifecycle` rows under
  Compliance.

