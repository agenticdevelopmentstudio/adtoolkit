
None of these five files uses a localization mechanism; every user-facing
string is a hardcoded English literal. Per this recipe's authoring rules, a
hardcoded string is a fact to record, not a gap to excuse.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a — `500` | `GitHub login is not configured` | `/auth/github/start`, missing `clientId`/`publicBaseUrl` |
| n/a — `400` | `Invalid OAuth state` | `/auth/github/callback`, missing/mismatched state |
| n/a — `502` | `GitHub is unreachable` | `ghFetch` catch (network failure or timeout) |
| n/a — `502` | `GitHub token exchange failed` | `exchangeCode`, non-`ok` token response |
| n/a — `401` | `GitHub authorization failed` | `exchangeCode`, `ok` response with no `access_token` |
| n/a — `502` | `Could not read the GitHub profile` | `exchangeCode`, non-`ok` `/user` response |
| n/a — `502` | `GitHub profile is missing an id` | `exchangeCode`, non-finite/non-numeric profile `id` |

