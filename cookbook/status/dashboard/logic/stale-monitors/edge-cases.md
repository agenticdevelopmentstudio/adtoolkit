
- **Empty services**: The result MUST be `[]`. The banner then renders nothing.
- **`downSince` null or empty**: A `"down"` service MUST be skipped, since the onset is unknown.
- **Malformed `downSince`**: `Date.parse` returns `NaN`, the age is non-finite, and the service MUST be skipped. The explicit `Number.isFinite` guard exists because `NaN < thresholdMs` is `false` and would otherwise let the row through.
- **`downSince` in the future**: The age is negative, which is below any non-negative threshold, so the service MUST be skipped.
- **Age exactly at threshold**: The service MUST be included (the comparison is strict less-than for exclusion).
- **`nowMs` that is `NaN`**: Every age is non-finite, so the result MUST be `[]`.
- **`thresholdMs` of 0 or negative**: Every down service whose finite age is at least `thresholdMs` MUST be selected (with 0, every onset at or before `nowMs`); the function does not validate the threshold. The sole caller never passes one.
- **`thresholdMs` of `NaN`**: `ageMs < NaN` is `false`, so every down service with a finite age MUST be selected. This is a fact of the comparison; the argument is typed `number` and the only caller uses the default.
- **`thresholdMs` of `Infinity`**: Every service MUST be left unselected.
- **Empty-string `error`**: `detail` MUST be `""`, not the status-code or `"down"` fallback, because `??` only replaces `null` and `undefined`.
- **Equal ages**: Rows MUST keep their relative input order.
- **Host that no longer resolves**: The row MUST still be offered, with `dnsOk false`; DNS is explanatory only.
- **Concurrent access**: Not applicable. The function is stateless and runs on single-threaded JavaScript.
- **Error states and offline**: Not applicable. The function performs no I/O. A failed retire is the caller's `deleteEndpoint` error, which the banner surfaces as `"Retire failed: …"`.

