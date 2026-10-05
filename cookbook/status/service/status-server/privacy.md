
**Data collected**: No PII collected by the server itself. The `/public/status-summary` endpoint exposes aggregated deployment status (service names, down/degraded indicators) and timestamps from open issues; this data is intentionally public.

**Storage**: Status data is persisted via the pluggable `Storage` interface; the server does not specify where or how storage is implemented.

**Transmission**: HTTP responses are sent over CORS-gated HTTPS (by convention; the server does not enforce TLS itself). Authenticated routes pass through the `AuthGate` port, which owns the credential mechanism (the default adapter lives in `auth/default-adapter`).

**Retention**: Retention policy is determined by the `Storage` implementation; the server does not enforce data deletion or expiry.

