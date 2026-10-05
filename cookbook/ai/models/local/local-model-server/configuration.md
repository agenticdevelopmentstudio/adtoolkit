
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `baseURL` | string | none — required per call | Passed to loopback detection and native tags URL derivation; the caller's configured, OpenAI-compatible base URL for a provider, e.g. `"http://localhost:11434/v1"`. |
| `data` | bytes | none — required per call | Passed to the response parser; the raw response body of a request to the URL native tags URL derivation produced, fetched and supplied by the caller. |
| `model` | string | none — required per call | Passed to the size resolver; the model identifier to look up, e.g. `"llama3.1:8b"`, optionally matched via the `":latest"` fallback. |
| `sizes` | map of string to integer | none — required per call | Passed to the size resolver; the map a prior response-parser call produced, supplied by the caller (typically the model catalog's cache). |

No environment variable, settings key, feature flag, or injected dependency
configures the model server helper; it has no dependency beyond standard
URL and data parsing, and every input is an explicit argument.

