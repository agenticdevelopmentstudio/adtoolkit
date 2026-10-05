
### Query identity and options

- **query-key**: The state MUST register its read under the cache key `status`.
- **result-type**: The state MUST return the full read-result object produced by the underlying read mechanism, with no fields added, removed or renamed.
- **refetch-on-focus**: The read MUST refetch automatically when the application regains focus, so a stale `status` read refetches without a manual reload.
- **no-interval**: The read MUST NOT set its own periodic refresh interval; periodic refresh is owned outside this state (the app's refresh-all state refetches every non-live, non-disabled read on a 60-second default interval).
- **no-enabled-option**: The state MUST take no parameters and MUST NOT support being conditionally disabled, so every active consumer is an active observer.
- **client-defaults**: The read MUST NOT set its own retry count, staleness duration, cache lifetime or timeout; those come from the host cache's defaults.

### Request

- **client-injection**: The read MUST obtain its transport from an injected API client, which resolves to an overriding client when one has been provided and to the same-origin default client otherwise.
- **request-path**: Each read MUST call the client's request operation for `/status` exactly once, with no extra request options, so the request is a `GET` to `<basePath>/status` (`/api/status` with the default base path).
- **raw-fetch**: The state MUST use the client's basic request operation, not its JSON-decoding convenience method, so no `Content-Type` header is added and the convenience method's own `${method} ${url} → ${status}` error format is not used.

### Success path

- **success-ok**: When the response has `ok === true` (status 200–299), the read MUST resolve to the parsed JSON body.
- **success-unvalidated**: The parsed body MUST be returned as the response type by assertion only; the state performs no runtime shape check on `overall`, `services` or `checkedAt`.
- **success-parse-failure**: When a successful response body is not valid JSON, the read MUST fail with the rejection produced by parsing it as JSON, not with a `status <code>` message.

### Error path

- **error-body-read**: When the response has `ok === false`, the state MUST attempt to parse the body as JSON and read its `error` field.
- **error-detail-message**: When that `error` field is a non-empty string, the read MUST fail with an error whose message is the string unchanged.
- **error-status-fallback**: When the body is not JSON, has no `error` field, or its `error` is an empty string, `null` or otherwise falsy, the read MUST fail with an error whose message is `status <code>`, where `<code>` is the numeric HTTP status (for example `status 503`).
- **error-parse-swallowed**: A JSON parse failure while reading the error body MUST NOT escape; it MUST be converted to the `status <code>` fallback message.
- **error-nonstring-detail**: The state MUST NOT narrow `error` to a string at runtime; a truthy non-string `error` (for example an object) MUST be used as the error message source as-is, producing its string coercion as the message (for an object, `[object Object]`).
- **error-message-only**: The failure MUST carry only a message; the HTTP status code and response body are not attached to it as additional properties.
- **network-failure**: When the underlying request itself fails (network unreachable, DNS failure, CORS), the read MUST fail with that failure unchanged.

### Caching, concurrency and side effects

- **shared-cache**: All consumers under one shared cache MUST share the single `status` read; concurrent mounts MUST NOT start more than one in-flight request beyond the cache's own deduplication.
- **no-cancellation**: The read MUST NOT accept or forward a cancellation signal; an in-flight request runs to completion even when the read is cancelled or its consumers unmount.
- **side-effects**: The state's only side effect MUST be the one `GET /status` request per read; it MUST NOT write storage, log, emit analytics, or mutate server state.
- **server-contract**: The response body shape and the `{ error }` failure body are owned by the status service's `/status` endpoint; this state surfaces whatever that endpoint sends, unchanged apart from the error-message extraction above.
- **client-only**: Status State MUST run only in a live client execution context; it has no server-only or universal-rendering variant.

