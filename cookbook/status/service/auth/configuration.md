
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `config.authDisabled` | `boolean` (StatusConfig field) | host-supplied | Dev/e2e escape hatch; when `true`, `authenticate` grants tier `admin` to every request with no other check. Documented as "never true in production." |
| `config.cookieSecure` | `boolean` (StatusConfig field) | host-supplied | Whether the `status_auth` and `gh_oauth_state` cookies carry `Secure`. `cookie.ts`'s comment documents a `COOKIE_INSECURE=1` opt-out for http local dev/e2e; reading that environment variable is the host's env adapter's job, external to these five files. |
| `config.peerToken` | `string` (StatusConfig field) | host-supplied, empty disables | Shared secret a peer monitor presents as a bearer on `/snapshot` only. Empty string disables the peer-token path entirely. |
| `config.publicBaseUrl` | `string` (StatusConfig field) | host-supplied | Browser-facing origin used to build the GitHub OAuth `redirect_uri`; empty makes `/auth/github/start` respond `500`. |
| `config.github.clientId` | `string` (StatusConfig field) | host-supplied | GitHub OAuth app client id; empty makes `/auth/github/start` respond `500`. |
| `config.github.clientSecret` | `string` (StatusConfig field) | host-supplied | GitHub OAuth app client secret; used only server-side in `exchangeCode`'s POST body. |
| `config.github.fetchTimeoutMs` | `number \| null` (StatusConfig field) | `null` (code default `8000`) | Deadline for each outbound GitHub API call in `ghFetch`, via `AbortSignal.timeout`. |
| `config.adminEmails` | `readonly string[]` (StatusConfig field, consumed via `roleForEmail`, external to these five files but called from `github.ts`) | host-supplied | Lower-cased email allowlist auto-promoted to `role: 'admin'` on first GitHub login. |
| `SESSION_COOKIE` | module constant (`cookie.ts`) | `'status_auth'` | The one cookie name this package's session logic reads and writes. |
| `MAX_AGE_SECONDS` | module constant (`cookie.ts`) | `2592000` (30 days) | Fixed `maxAge` for the session cookie; not configurable per call. |
| `STATE_COOKIE` | module constant (`github.ts`) | `'gh_oauth_state'` | CSRF-nonce cookie name for the OAuth start/callback pair; fixed `maxAge: 600`. |
| `COST` | module constant (`password.ts`) | `10` | bcrypt cost factor for both `hashPassword` and `DUMMY_PASSWORD_HASH`. |
| `storage` | injected `Storage` (`AuthStore`/`TokenStore`) | required | Every user, session, and API-token lookup in `default-adapter.ts` and `github.ts` goes through this port; its implementation is external to these five files. |

