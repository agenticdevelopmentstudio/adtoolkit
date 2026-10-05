
This file's `error` strings are hardcoded English and are the exact text surfaced to operators through the health sync and the `/api/status` no-DB fallback (per the Overview); none of them route through a localization mechanism.

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| n/a | `DNS: <reason>` | `error` when `resolveDns` reports `ok: false` (`dns-failure-short-circuits-http`); `<reason>` is `"does not resolve"` or `"resolution timed out"` |
| n/a | `Unexpected status <code>` | `error` when `classify` returns `"down"` and the marker-missing branch does not apply (`down-error-message-selection`) |
| n/a | `expected content "<marker>" not found in response` | `error` when the configured `expectBody` marker is missing and the body was read to completion |
| n/a | `expected content "<marker>" not found in the first <N>KB (body truncated — marker may lie beyond the cap)` | `error` when the marker is missing and the capped read was truncated (`body-truncation-annotates-marker-error`) |
| n/a | `Timeout after <ms>ms` | `error` when the fetch attempt is classified as the whole-leg timeout (`fetch-failure-timeout-classification`) |
| n/a | `Unknown error` | `error` fallback when a caught fetch rejection is not an `Error` instance |
| n/a | `[probe] body read failed after headers: <message>` | `console.error` line for a non-abort mid-stream body-read failure (`body-read-error-not-fatal`) |

