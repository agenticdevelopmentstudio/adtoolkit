
- **Null platform**: A row with `platform: null` MUST be treated as a deploy row with no platform name. `platformText`, `platformLink` and `deployOutcome` MUST be null.
- **Empty platform string**: `platform: ""` MUST behave like null, because the platform-name test is a truthiness check.
- **Unknown platform**: A platform the platform label function does not know MUST still produce a platform name, its own key lower-cased (for example `fly-io`). A tone of `bad` or `good` then yields a deploy outcome.
- **Endpoint with no URL**: An endpoint row with both `liveUrl` and `sourceUrl` null MUST use the row's `name` as the title and `null` as `titleUrl`.
- **Empty-string URLs**: The title and link fallbacks treat only null or absent as missing, not empty strings. An empty `liveUrl` on an endpoint row MUST give `titleUrl` `""` and title equal to the row's `name`. The serializer then omits both the `url` and `link` lines.
- **Malformed endpoint URL**: A `liveUrl` that cannot be parsed as a URL MUST become the title unchanged. Because title and `titleUrl` are then equal, the `url` line MUST be omitted.
- **Empty `at`**: `at` is a required string. An empty `at` with no `downSince` MUST give `since` `""`, since the fallback does not skip an empty string. The serializer then omits the `since` line.
- **Empty detail**: `detail: ""` MUST give `problem` null and `problemLink` null.
- **Zero values**: `statusCode: 0` and `responseTimeMs: 0` MUST be kept. They appear as `0` and `0ms` in both the detail and the text.
- **Resolved deploy row**: A status word starting with `[` MUST suppress `platformText`, `platformLink` and `deployOutcome`, even when the tone is `good`.
- **Commit body equal to subject**: A `commitBody` equal to `commitSubject` MUST NOT be appended to the text.
- **Multi-line error text**: `errorText` MUST be emitted verbatim, including its internal newlines, with no escaping or truncation.
- **Error states, offline, timeouts, cancellation**: Not applicable. The logic performs no I/O, has no dependency that can fail, and cannot be cancelled or time out.
- **Concurrent calls**: Not applicable. The functions are pure and hold no shared state.

