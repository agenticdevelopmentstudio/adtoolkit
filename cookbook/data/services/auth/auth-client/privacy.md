
- **Data collected**: The access token (a bearer credential, not itself
  PII); a cached user record (`id`, `email`, `name`, `avatarUrl`, `slug`,
  `capabilities`, `authMethods`, `attributes`); TOTP secrets/`otpauthUri`
  and WebAuthn ceremony payloads pass through this module in memory only and
  are never persisted by any part of it; recovery codes are returned once by
  the recovery-codes regeneration and are likewise not persisted here. The
  refresh token is explicitly never read or persisted
  (**refresh-token-never-persisted**). The error-report context is typed
  scalars-only (no PII, request bodies, or ids) by declared contract.
- **Storage**: The access token and cached user live in a persistent
  client-side store under the configured storage key and
  `` `${storageKey}:user` `` as plaintext JSON — readable by any script
  running on the page (the standard SPA storage/XSS tradeoff; this contract
  does not encrypt or otherwise protect that value beyond keeping the
  refresh token out of it). The CSRF link nonce, the post-login return-to
  path, the once-per-tab restore guard, and the pending-link intent live in
  a session-scoped client-side store, scoped to one tab and cleared when it
  closes.
- **Transmission**: The access token is sent only via the `Authorization:
  Bearer` header (see Security). Credentials are included on the refresh
  endpoint and every central-login/MFA endpoint so the HttpOnly
  refresh/central-session cookies travel with the request; the
  silent-restore preflight check deliberately omits credentials because its
  question needs no session context. This module never reads the HttpOnly
  refresh or central session cookies itself — only the server sets and
  reads them.
- **Retention**: The access token and cached user persist in the persistent
  client-side store until an explicit clear (logout, or a refresh that gives
  up — **refresh-failure-clears-when-unresolved**) or until the host clears
  its own storage; this module enforces no client-side TTL on the access
  token — expiry is discovered only when the server returns a `401`, which
  triggers a refresh attempt.

