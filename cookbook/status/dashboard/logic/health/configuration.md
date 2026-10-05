
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `statusCode` | `number` | none (required) | The HTTP status code the probe received. |
| `responseTimeMs` | `number` | none (required) | The measured response latency in milliseconds. |
| `expectedStatus` | `number` | none (required) | The endpoint's configured expected status. A match passes the gate even outside 2xx. |
| `isHealthKind` | `boolean` | `undefined` (falsy) | True for a health-kind endpoint whose JSON `status` has to read `"ok"`. |
| `bodyText` | `string` | `undefined` | The response body, only needed for the health-kind check. |
| `bodyMarkerMissing` | `boolean` | `undefined` (falsy) | True when the configured `expectBody` marker was not found in the body. |
| `HEALTH_CHECK_TIMEOUT_MS` | constant | 10 000 | The default probe timeout, compiled in. `classify` does not read it. |
| `DEGRADED_THRESHOLD_MS` | constant | 2 000 | The latency above which a success candidate is degraded, compiled in. |

The module reads no environment variables and no settings keys, and takes no injected dependencies. It has no imports.

