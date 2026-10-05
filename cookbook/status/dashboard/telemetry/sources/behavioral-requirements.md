
### Shared contract

- **source-shape**: Each source MUST be an object exposing exactly one async operation, `get`, that takes the injected API client and resolves to a telemetry snapshot.
- **api-injection**: Each source MUST issue every HTTP request through the injected client's request operation, with a path relative to the client's base (for example `/telemetry`), never through a global network call or an absolute URL.
- **get-only-requests**: Each source MUST call the injected client's request operation with a path and no extra options, so every request is a plain GET with no custom headers or body.
- **stateless**: Each source MUST hold no state between calls; every `get` issues fresh requests and returns a new snapshot.
- **no-cache**: A source MUST NOT read or write the snapshot cache; caching belongs to the cache abstraction and the telemetry state.
- **interchangeable**: Both sources MUST resolve to the same snapshot shape so the composition root can swap one for the other with no change to any consumer.
- **error-propagation**: A source MUST reject the returned promise on failure rather than resolving to an empty or partial snapshot; it MUST NOT catch or log errors itself.
- **network-rejection**: When the injected client's request rejects (network failure, aborted request), the source's `get` MUST reject with that same error, unwrapped.
- **json-parse-rejection**: When a response with a 2xx status carries a body that is not valid JSON, `get` MUST reject with the error thrown while parsing the body as JSON.
- **no-timeout**: A source MUST NOT impose its own timeout or cancellation; a request that never settles leaves `get` pending.
- **no-retry**: A source MUST NOT retry a failed request; retry policy belongs to the caller (the telemetry state allows one retry).
- **response-shape-trusted**: Both sources trust the backend's response contract: they treat the parsed JSON as already matching the expected shape and perform no runtime validation, so a 2xx body missing `errors`, `analytics`, `metrics` or `generatedAt` resolves as a snapshot whose fields are `undefined`, with no error. Guaranteeing the shape is the backend's job; a source MAY add validation but does not today.

### Live source

- **live-endpoint**: The live source's `get` MUST issue exactly one request, to `/telemetry`.
- **live-status-check**: When the `/telemetry` response has `ok === false` (status outside 200–299), the live source's `get` MUST reject with an error whose message is `telemetry ${status}` (for example `telemetry 503`), without reading the body.
- **live-passthrough**: On an `ok` response, the live source's `get` MUST resolve to the parsed JSON body unchanged, including the server-supplied `generatedAt`.
- **live-no-database**: The live source MUST depend only on `/telemetry`; it MUST NOT call `/errors` or `/analytics`.

### Persisted source

- **turso-endpoints**: The persisted source's `get` MUST issue exactly two requests, `/errors` and `/analytics`.
- **turso-parallel**: The persisted source's `get` MUST start both requests concurrently and wait for both responses before checking either status.
- **turso-network-rejection-order**: When either request rejects, the persisted source's `get` MUST reject with the first rejection to settle, and MUST NOT check any status.
- **turso-errors-status**: When the `/errors` response is not `ok`, the persisted source's `get` MUST reject with an error whose message is `errors ${status}`.
- **turso-analytics-status**: When the `/errors` response is `ok` and the `/analytics` response is not, the persisted source's `get` MUST reject with an error whose message is `analytics ${status}`.
- **turso-status-precedence**: When both responses are not `ok`, the persisted source's `get` MUST reject with the `errors ${status}` message; the `/analytics` status is not reported.
- **turso-body-order**: The persisted source's `get` MUST check both statuses before parsing either body, then parse `/errors` before `/analytics`.
- **turso-errors-projection**: The persisted source's `get` MUST take the snapshot's `errors` from the `errors` property of the `/errors` body and discard any other properties.
- **turso-analytics-projection**: The persisted source's `get` MUST take the snapshot's `analytics` from the `metrics` property of the `/analytics` body, renaming `metrics` to `analytics`, and discard any other properties.
- **turso-generated-at**: The persisted source's `get` MUST set `generatedAt` to the client's clock at assembly time, not to any server-supplied time.
- **turso-snapshot-keys**: The snapshot the persisted source's `get` resolves MUST contain exactly the keys `generatedAt`, `errors` and `analytics`.

### Composition

- **default-source**: The composition root MUST export the active source as the live source today; changing the one marked line MUST be the only edit required to switch backends.
- **single-threaded**: Concurrent calls to either source's `get` MUST NOT share state and MAY interleave freely, each resolving independently.

