
- **Data collected**: a GitHub profile's `id`, `email`, and display name
  (`name`/`login`) during OAuth login (`github.ts`); a plaintext password
  for the duration of one `hashPassword`/`verifyPassword` call
  (`password.ts`); an opaque session token and an opaque `sts_` API bearer
  token, read but never decoded (`cookie.ts`, `default-adapter.ts`).
- **Storage**: none of these five files writes to persistent storage
  directly — they call the `AuthStore`/`TokenStore` ports
  (`createUser`, `attachGithubId`, `createSession`, `validateApiToken`),
  whose implementation (hashing, table layout) is external and not
  specified here. `toAuthUser`, the port's own projection (external to
  these files), drops the password hash before a `UserRecord` is exposed as
  an `AuthUser`.
- **Transmission**: the session and OAuth-state cookies are `httpOnly`
  always, and carry `Secure` whenever `config.cookieSecure` is true; a host
  opts out only for local/e2e http, per `cookie.ts`'s documented
  `COOKIE_INSECURE` escape hatch (read by the external env adapter, not
  these files). GitHub API calls in `github.ts` are made to hardcoded
  `https://` origins.
- **Retention**: the session cookie has a fixed 30-day `maxAge`
  (`MAX_AGE_SECONDS`) and the OAuth-state cookie a fixed 600-second
  `maxAge`; both are set unconditionally by these files with no
  configurable override. Server-side session/token expiry and revocation
  (`revokeSession`, `revokeApiToken`) are the `Storage` ports' job, called
  from outside these five files.

