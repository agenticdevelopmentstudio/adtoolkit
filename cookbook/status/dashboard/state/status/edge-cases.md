
- **Empty services list**: A `200` body with `services: []` MUST resolve as-is; the state does not treat an empty list as an error (MUST).
- **Missing or malformed fields in a 200 body**: A body lacking `services` or `checkedAt`, or with wrong types, MUST resolve without error because the body is cast, not validated; consumers such as the dashboard view guard by defaulting a missing services list to an empty one (MUST, as implemented).
- **Non-JSON 200 body**: The read MUST fail with the JSON parsing error (MUST).
- **Non-JSON error body**: The parse failure MUST be caught and replaced by `status <code>` (MUST).
- **Empty-string or null `error`**: Falsy detail MUST fall back to `status <code>` (MUST).
- **Non-string `error`**: A truthy object or number is used unconverted, yielding a coerced message such as `[object Object]` or `42`; the reason is lossy but the failure is still reported (MUST, as implemented).
- **Network unreachable / offline**: The transport rejects and the read fails with that rejection; the state adds no retry, backoff or offline detection of its own beyond the host cache's defaults (MUST).
- **Timeout**: The state sets no timeout; a request that never settles leaves the read pending until the platform's network stack gives up (MUST, as implemented).
- **Cancellation / unmount**: The request is not tied to a cancellation signal, so an unmounted or cancelled read's request still completes and its result may populate the cache (MUST, as implemented).
- **Concurrent callers**: Reads are deduplicated by cache key, so concurrent mounts share one in-flight request; there is no interleaving to order (MUST).
- **No provider mounted**: When no client is injected, the state falls back to the module-level default client at `/api` (MUST).
- **Window focus while fresh**: Refetch-on-focus refetches only when the read is stale per the host's staleness setting; a fresh read is not refetched on focus (MUST, per the cache's semantics).

