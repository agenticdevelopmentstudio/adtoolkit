
- **empty-checks**: A successful response with `checks: []` MUST resolve as data. Integrations applies no emptiness check.
- **malformed-body**: A body that is valid JSON but not shaped like `IntegrationsResponse` (for example, one missing `checks`) MUST resolve as data unchanged. Integrations does no shape validation, and a consumer reading `data.checks` gets nothing.
- **unknown-check-state**: A `state` or `overall` value outside `"ok" | "warn" | "error"` MUST pass through unchanged. The type is a compile-time-only constraint.
- **204-response**: A response with no body still counts as ok, so Integrations MUST attempt to parse the empty body. That fails and puts the query in its error state, unlike the client's JSON-body helper, which maps a no-content response to an empty result.
- **server-error**: A non-2xx status MUST produce an error whose message is `status <status>`. Retries after that follow the shared cache's policy; when the host sets none, the library default is 3 retries with exponential backoff. What the `/integrations` route returns is owned by the backend.
- **unreachable-server**: A failed request MUST surface as the query error. Integrations adds no retry, fallback data or message rewriting of its own.
- **error-after-success**: When a refresh fails after an earlier success, the shared cache MUST keep the previous `data` and set `error`. The two callers read only `data`, so they keep showing the last good snapshot.
- **ambiguous-error-message**: The failure message is the generic `status <status>`, which does not name the integrations endpoint. A consumer that logs the error cannot tell it from other queries by the message alone. This SHOULD be kept as-is for fidelity; see Design Decisions.
- **hung-request**: Integrations sets no timeout or cancellation signal, so a request that never settles MUST leave the query fetching indefinitely.
- **focus-while-fetching**: Regaining focus during an in-flight fetch MUST NOT start a second request. The shared cache deduplicates on the shared key.
- **no-provider**: With no status API provider mounted, Integrations MUST fall back to the same-origin default client, `/api`. With no shared cache mounted, the runtime fails when Integrations is used.

