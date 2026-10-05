
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| claude-o-auth-credential-001 | credential-fields, required-tokens | Construct a credential with only `accessToken: "a"` and `refreshToken: "r"`. | Both expiries are absent, scopes is empty, subscription type and rate-limit tier are absent. |
| claude-o-auth-credential-002 | expiry-unit-milliseconds, expiry-seconds-derived | Construct with `expiresAt: 1750000000000` and read the access expiry in seconds. | `1750000000`; the stored value is still `1750000000000`. |
| claude-o-auth-credential-003 | expiry-seconds-derived | Read the refresh expiry in seconds on a credential whose refresh expiry is absent. | Nothing. |
| claude-o-auth-credential-004 | value-equality | Compare two credentials identical except for the refresh token. | Not equal. |
| claude-o-auth-credential-005 | value-equality | Compare a credential with a copy of itself. | Equal. |
| claude-o-auth-credential-006 | codable-wire-form | Encode a credential with scopes `["user:inference"]`, then decode the result. | The decoded credential equals the original. |
| claude-o-auth-credential-007 | credential-fields | A rotated live credential `a2`/`r2` with `expiresAt: 2000` is compared to a saved credential `a1`/`r1` with `expiresAt: 1000` (as `ClaudeLiveLoginRecordTests` does). | They are not equal, so the saved record is treated as stale. |

