
- **Empty lists**: A 2xx body with `errors: []` and `analytics: []` (or `metrics: []`) MUST resolve to a snapshot with empty arrays; a source MUST NOT treat it as a failure.
- **Missing field in a 2xx body**: A `/errors` body without an `errors` key resolves with `errors: undefined`; a `/telemetry` body without `analytics` resolves without it. See response-shape-trusted.
- **Non-object 2xx body**: A `/errors` body of `null` MUST reject with the runtime error thrown when reading `.errors` of `null`; a `/telemetry` body of `null` resolves to `null` unchecked. See response-shape-trusted.
- **Redirects**: `ok` is judged on the final response after the request follows redirects; a 3xx that is not followed has `ok === false` and MUST reject with the status message.
- **Unconsumed bodies**: On a non-`ok` response the body is never read; on a persisted-source status failure the other response's body is also left unread. Neither source cancels those bodies.
- **Partial persisted-source success**: One endpoint succeeding and the other failing MUST reject the whole call; a source MUST NOT return a partial snapshot.
- **Hung request**: With no timeout, a request that never settles MUST leave `get` pending indefinitely; for the persisted source, one hung endpoint blocks the whole call even if the other failed with an HTTP status.
- **Concurrent calls**: Overlapping `get` calls MUST each issue their own requests and resolve independently. Deduplication, if any, is the caller's (the telemetry state's shared cache key).
- **Offline**: When the client is offline, the request rejects and `get` MUST reject with that error; showing a cached snapshot is the telemetry state's job.
- **Server behavior**: Which providers `/telemetry` polls, and how `/errors` and `/analytics` read the database, is owned by the backend service, not these sources.

