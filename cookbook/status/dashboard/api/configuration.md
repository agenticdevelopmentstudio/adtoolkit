
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| Base path | text | `/api` | Client-constructor/provider option; every relative path is joined onto this prefix by the url operation. |
| Network-request function | function | the platform's default | Client-constructor option; injected to install a test double or a polyfill, resolved fresh on every call (late-request-resolution). |
| Client | API client instance | none — the provider builds its own | Provider option; when given, the client accessor returns it verbatim instead of a provider-constructed client. |
| `body.environment` | one of: production, staging, testing | none — caller-supplied | endpoint create/update field; not validated against the allowed set by this client. |
| `body.platform` | one of: vercel, railway, cloudflare, crunchy | none — caller-supplied | endpoint create/update field; not validated against the allowed set by this client. |
| `body.kind` | one of: http, frontend, admin, health, custom, dns | none — caller-supplied, optional | omitted → server default `http`, per endpoint-kind-required. |
| `body.token` (peers) | text or none | omitted field = leave unchanged | see peer-token-write-semantics. |

