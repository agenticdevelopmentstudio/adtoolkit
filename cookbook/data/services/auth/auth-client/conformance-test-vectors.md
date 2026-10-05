
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| auth-client-001 | default-runtime-config | The runtime configuration read with no prior reconfiguration | `{ storageKey: 'auth_tokens', refreshPath: '/api/auth/refresh' }` |
| auth-client-002 | configure-auth-merges | Reconfiguring with `{ storageKey: 'x' }`, then reading the configuration | `refreshPath` unchanged; `storageKey === 'x'` |
| auth-client-003 | auth-api-base-resolution | AS base resolution given `'https://x.example.com/'` explicitly | `'https://x.example.com'` (trailing slash stripped) |
| auth-client-004 | as-endpoint-proxy-fallback | AS endpoint resolution for `/a` with no base and no environment variable set | `'/api/a'` |
| auth-client-005 | auth-tokens-shape | `{ accessToken: 'a', refreshToken: 'b' }` assigned as the token bundle | Valid; no other fields required or permitted |
| auth-client-006 | auth-user-shape | A user record omitting `slug` | Valid |
| auth-client-007 | has-capability-null-safe | The capability check applied to an absent user and `'billing'` | `false` |
| auth-client-008 | is-admin-derived | The admin check applied to a user with capabilities `['user', 'admin']` | `true` |
| auth-client-009 | tokens-from-response-precedence | Token extraction from `{ accessToken: 'A', token: 'T' }` | `{ accessToken: 'A', refreshToken: '' }` |
| auth-client-010 | tokens-from-response-refresh-token-blanked | Token extraction from a body carrying `{ token: 'T', refreshToken: 'server-rt' }` | `refreshToken === ''` |
| auth-client-011 | tokens-from-response-throws-when-absent | Token extraction from `{}` | Throws `/missing token/i` |
| auth-client-012 | token-storage-key-configurable | Reconfiguring with `{ storageKey: 'other_key' }`, then writing the token bundle | The persistent store holds a value under `'other_key'`; the default key is absent |
| auth-client-013 | token-read-off-browser-returns-null | Reading the token bundle with no interactive host environment present | Nothing |
| auth-client-014 | token-read-malformed-json-returns-null | The persistent store holds `'not json'` under the tokens key; reading the token bundle | Nothing |
| auth-client-015 | write-tokens-persists-and-announces | Subscribing to session changes, then writing the token bundle | Subscriber invoked exactly once; storage contains the tokens |
| auth-client-016 | clear-tokens-clears-sibling-user-key | Writing the cached user record, then clearing the token bundle | Reading the cached user record returns nothing; tokens key absent |
| auth-client-017 | read-access-token-derivation | Writing `{ accessToken: 'A', refreshToken: '' }`, then reading the stored access token | `'A'` |
| auth-client-018 | session-change-subscription | Subscribing, then unsubscribing, then writing the token bundle | The subscriber is not called |
| auth-client-019 | session-change-payload-free | Subscribing, then writing the token bundle | The subscriber is called with zero arguments |
| auth-client-020 | session-change-snapshot-iteration | Subscriber A unsubscribes subscriber B from inside A's own callback, both registered before one write | B is still invoked for that same announcement |
| auth-client-021 | decode-base64url-json-utf8-strict | Base64url-JSON decoding of an encoded `{ name: '東京' }` | `{ name: '東京' }` |
| auth-client-022 | decode-base64url-json-tolerates-missing-padding | Unpadded base64url of `{ sub: 'u', iat: 1 }` | `{ sub: 'u', iat: 1 }` |
| auth-client-023 | decode-base64url-json-never-throws | Base64url-JSON decoding of an invalid byte sequence | Nothing, no throw |
| auth-client-024 | read-token-subject-derivation | An access token whose second segment decodes to `{ sub: 'user-1' }`, stored | Reading the token's subject claim returns `'user-1'` |
| auth-client-025 | read-user-validates-shape | The persistent store holds `{"name":"x"}` (no `id`/`capabilities`) under the user key | Reading the cached user record returns nothing |
| auth-client-026 | write-user-persists-off-browser-noop | Writing the cached user record with no interactive host environment present | No throw; no storage write |
| auth-client-027 | refresh-single-flight-dedup | Two concurrent refresh calls, the underlying request resolving `{ token: 'NEW' }` | The underlying request is issued exactly once; both results are `'NEW'` |
| auth-client-028 | refresh-request-shape | The refresh operation invoked | Request issued with method `'POST'`, credentials included, body `'{}'` |
| auth-client-029 | invalidate-refresh-bumps-generation | A refresh in flight; refresh invalidation called | The next refresh call starts a fresh in-flight attempt, not the old one |
| auth-client-030 | refresh-generation-guard | A refresh in flight; refresh invalidation fires before the response lands; response then resolves OK | Result is nothing; no token bundle write |
| auth-client-031 | refresh-success-adopts-current-storage | A refresh in flight; clearing the token bundle (logout) fires before the OK response lands | Result is nothing; storage stays cleared |
| auth-client-032 | refresh-success-adopts-current-storage | A refresh in flight; a concurrent write of `{ accessToken: 'WINNER' }` fires before this attempt's OK response lands with `{ token: 'MINE' }` | Result is `'WINNER'`; storage still `'WINNER'` |
| auth-client-033 | refresh-failure-adopts-concurrent-winner | Non-OK response; storage already holds a token different from the one this attempt started with | Result is that current stored token; no clearing |
| auth-client-034 | refresh-failure-loser-recheck-delay | Non-OK response; a winner's write of `{ accessToken: 'WINNER' }` lands during the 300ms wait | After the wait, result is `'WINNER'` |
| auth-client-035 | refresh-failure-clears-when-unresolved | Non-OK response; no winner appears during the 300ms wait | Result is nothing; the token bundle is cleared |
| auth-client-036 | refresh-network-error-reports-and-clears | The underlying request rejects with a network-level error | Unconditional error reporting called with `{ feature: 'auth', step: 'tokenRefresh' }`; result nothing; tokens cleared |
| auth-client-037 | authed-fetch-bearer-attach | Writing `{ accessToken: 'TOK' }`, then an authenticated request to `/api/x` | Request header `Authorization: 'Bearer TOK'` |
| auth-client-038 | authed-fetch-default-content-type | The JSON-parsing helper called against `/api/x` with a stringified empty-object body and no `Content-Type` given | Sent request has `Content-Type: application/json` |
| auth-client-039 | authed-fetch-default-init | The base authenticated request helper called against `/api/x` with no options argument | Resolves normally; no throw reading request options |
| auth-client-040 | authed-fetch-401-refresh-retry-once | First request → `401`; refresh → `{ token: 'NEW' }`; retry → `200` | 3 underlying requests total; final result uses `Authorization: 'Bearer NEW'` |
| auth-client-041 | authed-fetch-throws-on-non-ok | Response not OK, status `500`, JSON body `{ error: 'boom' }` | Throws a typed HTTP error with message `'boom'`, `status === 500` |
| auth-client-042 | authed-json-rejects-204 | Response OK, status `204` | Throws `/Unexpected empty response/` |
| auth-client-043 | authed-request-discards-body | The body-discarding helper called against `/api/x` with method `DELETE` on a `200` response with a JSON body | Resolves to nothing; body never parsed by the caller |
| auth-client-044 | auth-http-error-shape | A typed HTTP error constructed with status `409`, message `'conflict'`, code `'ALREADY_LINKED'` | `.status === 409`, `.code === 'ALREADY_LINKED'`, `.name === 'AuthHttpError'`, behaves as an error |
| auth-client-045 | extract-error-message-precedence | Error-message extraction on `{ error: 'E' }`, `{ message: 'M' }`, `{ title: 'T' }`, `{}`, each with fallback `'fb'` | `'E'`, `'M'`, `'T'`, `'fb'` respectively |
| auth-client-046 | extract-error-message-precedence | Error-message extraction on `{ title: 'Bad Request', status: 400, detail: 'no GitHub App is configured' }` with fallback `'fb'` | `'no GitHub App is configured'` (RFC 9457 `detail` wins) |
| auth-client-047 | extract-error-code-precedence | Error-code extraction on `{ error: { code: 'X' } }` and on `{}` | `'X'` and nothing respectively |
| auth-client-048 | read-error-message-single-parse | The response's body-parse mocked to resolve once with `{ message: 'M' }` | Returns `'M'`; the body is parsed exactly once |
| auth-client-049 | exchange-sso-code-request-shape | The SSO code exchange called with `'code-1'` | `POST` to `'/api/oauth/signin/exchange'` with body `{"code":"code-1"}` |
| auth-client-050 | exchange-sso-code-network-retry-once | First request rejects (network-level), second resolves `200` with tokens | The underlying request is issued twice; result resolves with the tokens |
| auth-client-051 | exchange-sso-code-no-http-retry | The underlying request resolves not OK, status `401` | The underlying request is issued once per exchange call — no internal retry |
| auth-client-052 | exchange-sso-code-success-result | `200` response with `{ token: 'A', user: { id: 'u1' } }` | `{ tokens: { accessToken: 'A', refreshToken: '' }, user: { id: 'u1' } }` |
| auth-client-053 | exchange-sso-code-failure-throws | `401` response with `{ error: { message: 'invalid or expired exchange code' } }` | Throws a typed HTTP error with that message |
| auth-client-054 | link-provider-routes-to-as-host | The AS base environment variable set to `'https://api.example.com'`; the provider-link request invoked | Underlying request targets `'https://api.example.com/auth/link-provider'` |
| auth-client-055 | link-provider-authed-post | Writing `{ accessToken: 'at' }`, then the provider-link request | Request header `authorization: 'Bearer at'`; body deep-equals the input |
| auth-client-056 | retry-marker-hook | The retry-marker hook registered; a post-refresh retry occurs | The registered callback is called once with the retried request's options |
| auth-client-057 | webauthn-assertion-ceremony-shared | The options endpoint returns not OK | The shared ceremony throws using the extracted/fallback message |
| auth-client-058 | assert-second-factor-body | The second-factor assertion called with `('tok', url)` | The options POST body is `{"token":"tok"}` |
| auth-client-059 | assert-passwordless-passkey-body | The passwordless-passkey assertion called with `('id', url)` | The options POST body is `{"identifier":"id"}` |
| auth-client-060 | request-login-sms | Requesting a login SMS code with `'tok'` | `POST` to `'/api/auth/login/mfa/sms/send'` with `{"token":"tok"}` |
| auth-client-061 | complete-login-code | Completing login with `('tok', 'totp', '123456')` on a `200` | `POST` to `'/api/auth/login/mfa'`; returns the parsed body |
| auth-client-062 | complete-login-passkey | Completing login with a passkey given `'tok'` | `POST` to `'/api/auth/login/mfa/webauthn'` with the ceremony's `{ token, response }` |
| auth-client-063 | passwordless-passkey-login | Passwordless passkey login given `'id'` | `POST` to `'/api/auth/login/webauthn'` with the ceremony's `{ token, response }` |
| auth-client-064 | begin-login-navigation | Beginning login with `{ clientId: 'cookbook', authApiBase: 'https://api.hub.example.com' }` | The top-level view's target origin is `'https://api.hub.example.com'`, path `/oauth/signin/authorize`, `clientId=cookbook`, `return=<site>/auth/callback` |
| auth-client-065 | authorize-url-shape | Building the authorize URL with `{ clientId: 'adh', returnUrl: 'r', prompt: 'none' }` | Query has `clientId=adh`, `return=r`, `prompt=none` |
| auth-client-066 | provider-signin-url-shape | Building the provider sign-in URL with `{ clientId: 'adh', providerId: 'github', returnUrl: 'r' }` | Path `/oauth/signin/start`; query has `clientId`, `providerId`, `return` |
| auth-client-067 | sso-hint-cookie-check | The SSO-hint cookie present | The SSO-hint cookie check returns `true` |
| auth-client-068 | sso-checked-guard-tolerates-storage-failure | The session-scoped store's write mocked to throw | Marking the once-per-tab restore guard does not throw |
| auth-client-069 | silent-restore-guard-order | The inbound fragment carries `#code=abc` | The silent-restore decision returns `false` regardless of hint |
| auth-client-070 | silent-restore-evidence | No hint cookie, same-apex site | The silent-restore decision on an empty fragment returns `false` |
| auth-client-071 | registrable-domain-apex-comparison | AS host `api.agenticdeveloperhub.com`, site host `cookbook.com` | Treated as cross-apex; the silent-restore decision may return `true` even without a hint |
| auth-client-072 | preflight-sso-return-contract | Preflight response `{ allowed: true }`, `200` | The preflight check returns `true` |
| auth-client-073 | preflight-sso-return-contract | The preflight request throws | The preflight check returns `false` |
| auth-client-074 | preflight-sso-return-timeout | The preflight request never resolves | The preflight check resolves `false` after ~2000ms via its timeout |
| auth-client-075 | begin-silent-login-flow | No AS base configured | Beginning a silent login attempt returns `false`; the once-per-tab guard is still marked; no navigation |
| auth-client-076 | begin-silent-login-flow | AS base configured; preflight resolves `true` | Beginning a silent login attempt returns `true`; navigates to the authorize URL with `prompt=none` |
| auth-client-077 | parse-inbound-sso | Parsing `'#code=abc'`, `'#error=login_required'`, `''` | `{ code: 'abc' }`, `{ error: 'login_required' }`, nothing |
| auth-client-078 | strip-sso-fragment-preserves-other-keys | Stripping `'#site-switch&code=abc'` | `'#site-switch'` |
| auth-client-079 | sso-logout-navigation | SSO logout with `{ clientId: 'cookbook', authApiBase: 'https://api.hub.example.com' }` | Navigates to `/oauth/signin/logout` with `clientId=cookbook`, `return=<origin>/` |
| auth-client-080 | sso-switch-url | No AS base configured; building a site-switch URL for `'https://site.example.com/home'` | Returns `'https://site.example.com/home'` unchanged |
| auth-client-081 | current-return-to | The current location is `/a?b=1#c` | The current return-to value is `'/a?b=1#c'` |
| auth-client-082 | safe-return-to-rejects-cross-origin | Taking the return-to value with a stashed `'//evil.com/x'` | Returns nothing; storage key cleared |
| auth-client-083 | safe-return-to-rejects-cross-origin | A stashed value `'https://site.example.com/home?x=1#y'` (same origin, absolute) | Returns `'/home?x=1#y'` |
| auth-client-084 | stash-and-take-return-to-single-use | Stashing `'/home/x'`, then taking the return-to value twice | First call `'/home/x'`; second call nothing |
| auth-client-085 | read-central-params | Reading relayed parameters from `'?return=https%3A%2F%2Fx.example.com%2Fcb'` | `{ clientId: 'adh', returnUrl: 'https://x.example.com/cb' }` |
| auth-client-086 | read-central-params | Reading relayed parameters from `'?clientId=adh'` (no `return`) | Nothing |
| auth-client-087 | central-login-target-resolution | The current query carries a relayed `return`/`clientId` | Resolving the central-login target returns those relayed values, not a synthesized target |
| auth-client-088 | central-login-step-refuses-without-as-base | No AS base configured; central email/password login invoked | Throws before any network request; the underlying request is never issued |
| auth-client-089 | central-login-step-outcomes | Central email/password login's response `202` with an MFA-challenge body | Returns that challenge; no navigation |
| auth-client-090 | central-login-step-outcomes | Central email/password login's response `200` with `{ redirectUrl: 'https://bitbag.example.com/auth/callback#code=abc' }` | The top-level view navigates to that URL; the function returns nothing |
| auth-client-091 | central-login-step-request-shape | Central email/password login invoked with a credentials object | Request has credentials included; body includes `clientId`/`return` merged with `identifier`/`password` |
| auth-client-092 | central-email-login | Central email/password login with `{ identifier: 'a@b.com', password: 'p', clientId: 'adh', returnUrl: 'r' }` | `POST` to `'/oauth/signin/login'` with `{identifier,password,clientId,return}` |
| auth-client-093 | central-send-mfa-sms | Non-OK response from the SMS-send path on the AS | Throws a typed HTTP error with fallback `'Could not send a code.'` |
| auth-client-094 | central-complete-mfa-code | Central MFA code completion with `(target, 'tok', 'sms', '123456')` | `POST` to `'/oauth/signin/login/mfa'` via a central-login step |
| auth-client-095 | central-complete-mfa-passkey | Central MFA passkey completion with `(target, 'tok')` | The ceremony runs against the AS's MFA options endpoint, then `POST` to `'/oauth/signin/login/mfa/webauthn'` |
| auth-client-096 | central-passwordless-passkey | Central passwordless passkey login with `(target, 'id')` | The ceremony runs against the AS's passkey options endpoint, then `POST` to `'/oauth/signin/login/webauthn'` |
| auth-client-097 | begin-link-provider-csrf-nonce | Beginning a provider-link with `{ providerId: 'github', returnTo: '/home' }` | Navigates to the AS `/oauth/signin/start` with `link=1`; the stashed nonce equals the `linkNonce` query value |
| auth-client-098 | begin-link-provider-csrf-nonce | The session-scoped store's write mocked to throw | Beginning a provider-link returns `false`; no navigation occurs |
| auth-client-099 | mfa-status-fetch | Fetching MFA status on a `200` with an MFA-status body | `GET /api/account/mfa`; returns the parsed body |
| auth-client-100 | totp-enroll | Enrolling TOTP on a `200` with `{ secret, otpauthUri }` | `POST /api/account/mfa/totp/enroll`; returns that body |
| auth-client-101 | totp-confirm | Confirming a TOTP code with `'123456'` | `POST /api/account/mfa/totp/confirm` with `{"code":"123456"}` |
| auth-client-102 | totp-remove | Removing TOTP | `DELETE /api/account/mfa/totp` |
| auth-client-103 | webauthn-list | Listing WebAuthn credentials on a `200` with `{ items: [...] }` | `GET /api/account/mfa/webauthn`; returns that body |
| auth-client-104 | webauthn-register-ceremony | Registering a WebAuthn credential with `('passkey', 'My key')` | An options POST, then the registration ceremony, then a verify POST with `{ token, response, name: 'My key' }` |
| auth-client-105 | webauthn-remove | Removing a WebAuthn credential `'cred id/with slash'` | The delete path has the id percent-encoded |
| auth-client-106 | recovery-codes-regenerate | Regenerating recovery codes on a `200` with `{ codes: [...] }` | `POST /api/account/mfa/recovery/regenerate`; returns that body |
| auth-client-107 | preferred-method-set | Setting the preferred method to `'totp'` | `PUT /api/account/mfa/preference` with `{"method":"totp"}` |
| auth-client-108 | account-security-authed | No access token stored; any account-security operation invoked | Request carries no `Authorization` header, then a `401` triggers the same refresh-and-retry waterfall as any authenticated call |
| auth-client-109 | report-unexpected-status-gate | Unexpected-error reporting given a `401` typed HTTP error and given a `403` host-defined error with a compatible shape | Neither the console nor the sink is called for either |
| auth-client-110 | report-unexpected-status-gate | Unexpected-error reporting given a `503` typed HTTP error | Both the console and the sink are called |
| auth-client-111 | report-unexpected-dedup-window | The same message + context reported twice within 60000ms | The sink/console is called once, not twice |
| auth-client-112 | report-auth-error-unconditional | Unconditional error reporting regardless of status | The sink and the console are both called |
| auth-client-113 | report-never-throws | A registered reporter that throws; unexpected-error reporting invoked | Does not throw; the console is still called |
| auth-client-114 | set-auth-error-reporter-hook | Registering a sink, then unexpected-error reporting with `(err, { feature: 'x' })` | The sink is called with `(err, { feature: 'x' })` |
| auth-client-115 | provider-label-known-and-fallback | The provider label lookup for `'github'`, `'google'`, `'discord'` | `'GitHub'`, `'Google'`, `'Discord'` |
| auth-client-116 | oauth-error-message-known-codes-and-fallback | The OAuth error message lookup for `'account_exists'` and `'weird_code'` | Fixed account-exists message; `'Sign-in failed (weird_code)'` |
| auth-client-117 | link-copy-provider-substitution | The link-confirm title copy for `'github'` | `'Add GitHub to your account?'` |
| auth-client-118 | sensitive-data-classification / access-token-transmission | Unconditional error reporting called with a context object that happens to include an access-token field | Not applicable as a runtime check — the error-report context type documents the scalar-only contract; this vector records that no call site in this recipe passes a token as context |
| auth-client-119 | refresh-token-never-persisted | Token extraction from a body carrying `{ token: 'T', refreshToken: 'server-side-rt' }`, then writing the resulting bundle; inspecting the persistent store | The stored JSON's `refreshToken` field is `''`, never `'server-side-rt'` |
| auth-client-120 | token-subject-not-an-authorization-decision | An access token with an unsigned/forged `sub` claim | Reading the token's subject claim returns that claim's value unverified — documents that callers MUST NOT treat it as an authorization fact |

