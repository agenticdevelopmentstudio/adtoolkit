
### Data Shape

- **health-status-values**: `HealthStatus` MUST be exactly one of `"healthy"`, `"degraded"`, or `"down"`.
- **classify-input-shape**: `ClassifyInput` MUST carry the three required fields `statusCode: number`, `responseTimeMs: number`, and `expectedStatus: number`, plus the three optional fields `isHealthKind?: boolean`, `bodyText?: string`, and `bodyMarkerMissing?: boolean`.
- **classify-purity**: `classify(input)` MUST be a synchronous, side-effect-free function that returns a `HealthStatus` computed only from its `input` argument; it MUST perform no I/O, no logging, and no mutation of `input`.

### Success Range and Non-2xx Handling

- **success-status-range**: `classify` MUST treat `statusCode` as a successful response ("2xx") if and only if `statusCode >= 200 && statusCode < 300`.
- **non-2xx-non-expected-is-down**: `classify` MUST return `"down"` whenever `statusCode` is not a 2xx response AND `statusCode !== expectedStatus`, regardless of `responseTimeMs`, `isHealthKind`, `bodyText`, or `bodyMarkerMissing`.
- **expected-non-2xx-status-not-down**: `classify` MUST NOT return `"down"` on the sole basis of `statusCode` when `statusCode` is not a 2xx response but does equal `expectedStatus` (e.g. an endpoint whose `expectedStatus` is `401`); that case MUST proceed to the same health-kind, body-marker, and latency evaluation as a 2xx response.

### Classification Order

- **classification-evaluation-order**: `classify` MUST evaluate, and return on the first matching step, in exactly this order: (1) `statusCode` is neither a 2xx response nor equal to `expectedStatus` → `"down"`; (2) `statusCode` is a 2xx response AND `isHealthKind` is `true` AND `bodyText` is a non-empty string AND the parsed JSON body has a `status` field whose lower-cased string form is not `"ok"` → `"down"`, without evaluating `bodyMarkerMissing` or `responseTimeMs`; (3) `bodyMarkerMissing` is `true` → `"down"`; (4) `responseTimeMs > DEGRADED_THRESHOLD_MS` → `"degraded"`; (5) otherwise → `"healthy"`.

### Health-Kind JSON Check

- **health-kind-check-skipped-without-body-text**: When `statusCode` is a 2xx response and `isHealthKind` is `true` but `bodyText` is `undefined` or the empty string, `classify` MUST skip the JSON parse entirely and proceed directly to the `bodyMarkerMissing` and latency evaluation.
- **health-kind-json-down-on-non-ok-status**: When `statusCode` is a 2xx response, `isHealthKind` is `true`, and `bodyText` is a non-empty string, `classify` MUST parse `bodyText` as JSON and, when the parsed value is a non-null object containing a `status` property whose value, converted with `String(...)` and lower-cased, is not exactly `"ok"`, MUST return `"down"`.
- **health-kind-json-parse-failure-falls-through**: When parsing `bodyText` as JSON throws (a non-JSON body, e.g. an HTML page), `classify` MUST NOT return `"down"` on that basis and MUST continue to the `bodyMarkerMissing` and latency evaluation.
- **health-kind-json-missing-status-field-falls-through**: When the parsed JSON value is `null`, is not an object, or is an object with no `status` property, `classify` MUST NOT return `"down"` on that basis and MUST continue to the `bodyMarkerMissing` and latency evaluation.
- **health-kind-status-field-string-coercion**: `classify` MUST compare the parsed `status` field's value against `"ok"` by converting it with `String(...)` and calling `.toLowerCase()` first, so a `status` field of `"OK"`, `"Ok"`, or a non-string value such as `200` or `true` is compared as `"ok"`, `"ok"`, `"200"`, and `"true"` respectively — only a case-insensitive `"ok"` MUST count as healthy for this check.

### Body-Marker Check

- **body-marker-missing-is-down**: When `statusCode` is a 2xx response or equals `expectedStatus`, and the health-kind JSON check did not already return `"down"`, `classify` MUST return `"down"` when `bodyMarkerMissing` is `true`, regardless of `responseTimeMs`.

### Latency Classification

- **degraded-latency-threshold**: When none of the preceding down conditions apply, `classify` MUST return `"degraded"` when `responseTimeMs > DEGRADED_THRESHOLD_MS`, and MUST return `"healthy"` when `responseTimeMs <= DEGRADED_THRESHOLD_MS`; the comparison MUST be strictly-greater-than, so a `responseTimeMs` exactly equal to `DEGRADED_THRESHOLD_MS` MUST classify as `"healthy"`.

### Exported Constants

- **degraded-threshold-constant**: `DEGRADED_THRESHOLD_MS` MUST be exported with the value `2_000` (2000 milliseconds), and `classify`'s latency comparison MUST read this constant rather than a separately hard-coded literal.
- **health-check-timeout-constant**: `HEALTH_CHECK_TIMEOUT_MS` MUST be exported with the value `10_000` (10000 milliseconds); `classify` itself MUST NOT reference this constant in any of its comparisons — it is a caller-facing default that a probe's own request-timeout configuration reads (per `probe.ts`, external to this file, where it is the fallback for `ProbeOptions.timeoutMs`).

