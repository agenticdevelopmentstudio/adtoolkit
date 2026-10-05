
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `statusCode` (field of `ClassifyInput`) | `number` | none — required | The HTTP response status code the caller's probe observed. |
| `responseTimeMs` (field of `ClassifyInput`) | `number` | none — required | The elapsed milliseconds the caller's probe measured for the response. |
| `expectedStatus` (field of `ClassifyInput`) | `number` | none — required | The status code the caller configured the endpoint to expect (may be non-2xx). |
| `isHealthKind` (field of `ClassifyInput`) | `boolean \| undefined` | `undefined` (treated as `false`) | Whether the endpoint is configured as a `health`-kind endpoint, gating the JSON-body status check. |
| `bodyText` (field of `ClassifyInput`) | `string \| undefined` | `undefined` (treated as "no body") | The response body text the caller's probe read, when it read one. |
| `bodyMarkerMissing` (field of `ClassifyInput`) | `boolean \| undefined` | `undefined` (treated as `false`) | Whether the caller determined the endpoint's configured `expectBody` marker was absent from the response body. |
| `DEGRADED_THRESHOLD_MS` (exported constant) | `number` | `2_000` | The latency, in milliseconds, above which a successful response is classified `"degraded"` rather than `"healthy"`. |
| `HEALTH_CHECK_TIMEOUT_MS` (exported constant) | `number` | `10_000` | A caller-facing default request-timeout, in milliseconds; not read by `classify` itself, and used by `probe.ts` (external) as the fallback for `ProbeOptions.timeoutMs`. |

