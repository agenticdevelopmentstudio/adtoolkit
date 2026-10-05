
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| `tokens.missingToken` | Token response missing token/accessToken | Thrown by token extraction |
| `client.exchangeFallback` | Sign-in failed | The SSO code exchange's fallback error message |
| `client.httpFallback` | HTTP {status} | The base authenticated request helper's fallback error message |
| `client.emptyResponse` | Unexpected empty response (204 No Content); use authedRequest for endpoints with no body | The JSON-parsing helper's 204 guard |
| `mfa.passkeyCheckFailed` | Could not start the passkey check. | The second-factor assertion's fallback |
| `mfa.noPasskey` | No passkey is available for this account. | The passwordless-passkey assertion's fallback |
| `mfa.smsSendFailed` | Could not send a code. | Requesting a login SMS code's fallback |
| `mfa.codeMismatch` | That code didn't match. | Completing login with a code's fallback |
| `mfa.passkeyVerifyFailed` | Passkey verification failed. | Completing login with a passkey's fallback |
| `mfa.passkeyLoginFailed` | Passkey login failed. | Passwordless passkey login's fallback |
| `labels.accountExistsTitle` | Account already exists | The account-exists title copy |
| `labels.oauthAccountExists` | An account already exists for this email — sign in with your email and password instead. | The OAuth error message lookup for `'account_exists'` |
| `labels.linkFailedTitle` | Couldn't connect account | The link-failed title copy |
| `labels.loginDisabledTitle` / `loginDisabledBody` | We're not open just yet / The Hub isn't quite ready for visitors yet — please check back soon. | Shown when logins are disabled |
| `sso.misconfigured` | Sign-in is misconfigured on this site: NEXT_PUBLIC_AUTH_API_URL was not set when it was built... | A central-login step's thrown message when no AS base is configured |

Every string above is hardcoded English with no lookup table, ICU message, or
locale parameter anywhere in this recipe — there is no localization
mechanism in this component at all. This is a plain fact about the source,
not a gap: a port to a platform with an i18n layer MUST decide, as a design
choice outside this contract, whether and how to route these strings through
it.

