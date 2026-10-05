
- **Data collected**: none of this file's own. `classify` receives an already-fetched HTTP probe's status code, response time, expected status, and, optionally, a snippet of the probed endpoint's own response body, as plain function arguments from a caller (`probe()` in `probe.ts`, external to this file); it collects nothing itself.
- **Storage**: none. `classify` holds no state between calls and writes nothing; it returns a `HealthStatus` value to its caller and retains no reference to `bodyText` or any other field afterward.
- **Transmission**: none. This file makes no network or database call of its own; whether or how a `bodyText` snippet or a classification result travels anywhere is entirely the concern of callers external to this file.
- **Retention**: not applicable — this file holds no data across calls to retain.

