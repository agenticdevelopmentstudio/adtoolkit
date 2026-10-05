
### Types and constants

- **health-status-union**: `HealthStatus` MUST be exactly the string union `"healthy" | "degraded" | "down"`. It has no `"unknown"` member. Consumers that need one (the `status` fields in `src/types.ts`) widen it to `HealthStatus | "unknown"` themselves.
- **timeout-constant**: `HEALTH_CHECK_TIMEOUT_MS` MUST equal 10 000 ms. `classify` does not read it. It is the default probe timeout that the status-server probe reads as `opts.timeoutMs ?? HEALTH_CHECK_TIMEOUT_MS`.
- **degraded-threshold-constant**: `DEGRADED_THRESHOLD_MS` MUST equal 2 000 ms.
- **classify-input-shape**: `ClassifyInput` MUST carry the required fields `statusCode: number`, `responseTimeMs: number` and `expectedStatus: number`, plus the optional fields `isHealthKind?: boolean`, `bodyText?: string` and `bodyMarkerMissing?: boolean`.
- **body-marker-meaning**: Per its doc comment, `bodyMarkerMissing` MUST be `true` only when the endpoint's configured `expectBody` marker was NOT found in the response body. The caller computes it. `classify` never searches the body for a marker itself.

### classify

- **classify-signature**: `classify` MUST take one `ClassifyInput` and synchronously return a `HealthStatus`.
- **success-gate**: `classify` MUST treat a response as a success candidate when `statusCode` is in the range 200 to 299 inclusive, or when `statusCode` strictly equals `expectedStatus`.
- **non-success-down**: `classify` MUST return `"down"` when `statusCode` is outside 200 to 299 and does not equal `expectedStatus`. It does so regardless of latency, body or marker.
- **health-body-gate**: `classify` MUST inspect `bodyText` only when all three of these hold: `statusCode` is 2xx, `isHealthKind` is truthy, and `bodyText` is a non-empty string. A non-2xx `statusCode` that matches `expectedStatus` never has its body inspected.
- **health-body-not-ok-down**: When the health-body gate holds and `bodyText` parses as JSON to a non-null object with a `status` key, `classify` MUST return `"down"` if `String(status).toLowerCase()` is not `"ok"`.
- **health-body-ok-case-insensitive**: The `status` comparison MUST be case-insensitive, so `"ok"`, `"OK"` and `"Ok"` all pass the body check.
- **health-body-only-status-key**: The body check MUST read only the `status` key. Other keys, such as an `"ok": false` field beside `"status": "down"`, MUST NOT influence the verdict.
- **health-body-fallthrough-unparseable**: When `bodyText` is not valid JSON (for example an HTML page), `classify` MUST discard the parse failure and continue to the marker and latency checks. Per the source comment this is deliberate: "Non-JSON body (e.g. HTML page) — fall through to the marker/latency checks."
- **health-body-fallthrough-unknown-shape**: When the parsed JSON is not a non-null object with a `status` key (for example `{"result":"ok"}`, a JSON array, a string, a number or `null`), `classify` MUST continue to the marker and latency checks without returning `"down"`.
- **marker-missing-down**: For any success candidate that the body check did not already mark `"down"`, `classify` MUST return `"down"` when `bodyMarkerMissing` is `true`. This applies to a custom `expectedStatus` match as well as to a 2xx.
- **marker-absent-neutral**: When `bodyMarkerMissing` is `false` or `undefined`, the marker MUST NOT change the verdict.
- **latency-degraded**: For a success candidate that passed the body and marker checks, `classify` MUST return `"degraded"` when `responseTimeMs` is strictly greater than `DEGRADED_THRESHOLD_MS`.
- **latency-healthy**: For a success candidate that passed the body and marker checks, `classify` MUST return `"healthy"` when `responseTimeMs` is less than or equal to `DEGRADED_THRESHOLD_MS`.
- **check-order**: `classify` MUST apply its checks in this order: status gate, then health body, then marker, then latency. A `"down"` from an earlier check MUST short-circuit, so a slow response that fails the body or marker check is `"down"`, not `"degraded"`.
- **no-input-validation**: `classify` MUST NOT validate its numeric inputs. A non-finite `statusCode` fails the status gate and yields `"down"`. A `NaN` `responseTimeMs` fails the greater-than comparison and yields `"healthy"`. A negative `responseTimeMs` also yields `"healthy"`.

### Purity and concurrency

- **pure-function**: `classify` MUST be pure. It MUST NOT perform I/O, log, mutate its input, or throw on any input of the declared types. The only exception it can raise internally, from `JSON.parse`, is caught locally.
- **single-threaded**: The module holds no state and runs on the single JavaScript thread, so concurrent calls cannot interleave and need no ordering rule.
- **server-copy-identity**: This file MUST stay identical to `status-server/src/monitor/health.ts`, because the dashboard's `HealthStatus` type describes values the server's `classify` produced. No parity test enforces this. status-web has parity tests for `deploy-status` and `board-types`, but none for `health`, so drift between the two copies would go undetected.

