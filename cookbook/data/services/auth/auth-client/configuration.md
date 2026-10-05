
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `storageKey` | string (via reconfiguring auth) | `'auth_tokens'` | Persistent-store key for the persisted token bundle; the cached-user key is `` `${storageKey}:user` `` |
| `refreshPath` | string (via reconfiguring auth) | `'/api/auth/refresh'` | Same-origin path the cookie-first refresh POST targets |
| `NEXT_PUBLIC_AUTH_API_URL` | environment variable | unset | Absolute AS base URL; when unset, every AS-bound call falls back to the same-origin `/api` proxy (or, for a central-login step, refuses outright) |
| The default exchange path | exported constant | `'/api/oauth/signin/exchange'` | Default path the SSO code exchange posts the one-time code to |
| The exchange network-retry delay | internal constant | `750` ms | Pause before the SSO code exchange's single network-failure retry |
| The loser-recheck delay | internal constant | `300` ms | Pause a losing concurrent refresh waits before re-reading storage |
| The report dedupe window | internal constant | `60000` ms | Per-signature throttle window for unexpected-error reporting |
| The preflight timeout | internal constant | `2000` ms | Abort timeout for the silent-restore preflight check's GET |
| The login-time MFA/passkey paths | exported constants | `'/auth/login/mfa/sms/send'`, `'/auth/login/mfa/webauthn/options'`, `'/auth/login/webauthn/options'` | Shared login-time MFA/passkey paths, reused by both the site-login and central-login clients |
| The default callback path | internal constant | `'/auth/callback'` | Default in-site route the AS bounces the exchange code back to |
| `clientId` | caller-supplied option | `'adh'` | OAuth client id sent on every AS-bound navigation/POST |
| The error-reporter hook | injected hook | none | Host-supplied sink for error reporting; none means console-only |
| The retry-marker hook | injected hook | none | Host-supplied callback tagging the exact request options of a retried request |
| Session-change subscription | injected subscription | n/a | Caller-registered callback invoked on every token write/clear |

