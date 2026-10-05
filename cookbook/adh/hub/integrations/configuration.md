
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `BASE` | fixed constant, `"/api/integrations"` | fixed | Not injectable; every request path is built from it. |
| `OAUTH_CALLBACK_PATH` | fixed constant, `"/integrations/oauth-callback"` | fixed | The client route the OAuth/app-install redirect lands on; shared by the callback-URL builder and the callback page. |
| `OAUTH_STATE_TTL_MS` | fixed constant | `600000` (10 min) | How long a minted `state` is treated as fresh by this client's pre-flight check; mirrors (loosely) the backend's own TTL. |
| `OAUTH_STATE_FUTURE_SKEW_MS` | fixed constant | `60000` (1 min) | How far ahead of this client's clock an issuer's `iat` may be before this pre-flight treats the state as not-yet-valid. |
| `OAUTH_STATE_CLOCK_GRACE_MS` | fixed constant | `30000` (30 s) | Added to both bounds of the freshness window so this client's check can only be more permissive than the backend's own, never stricter. |
| `ecosystemId` (caller parameter) | string | none — required on nearly every call | The ecosystem every provider-config, connection, and OAuth-start call is scoped to; percent-encoded in every path/query use. |
| `providerId` (caller parameter) | string | none — required on provider-scoped calls | A catalog provider's id; percent-encoded. |
| `configId` / `connectionId` (caller parameter) | string | none — required on id-addressed calls | A provider config's or connection's own id/rdid; percent-encoded. |
| `body` (varies by operation) | a JSON object matching that operation's documented fields (the provider-config input, the connect-request's six type-keyed variants, the transfer/register/link-token/sync-settings/adopt-installations bodies) | none — required except creating a link token's, which defaults to `{}` | JSON-serialized verbatim as each write's body; see the matching Behavioral Requirement for the exact shape sent. |

