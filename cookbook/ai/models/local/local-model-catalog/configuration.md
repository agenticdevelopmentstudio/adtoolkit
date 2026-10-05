
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `fetcher` | function: URL → response bytes, or failure | built-in live fetch implementation | Injected fetch function, supplied at construction. Tests substitute a stub to avoid real networking and to force success/failure sequences. |
| `successTTL` | number (seconds) | `300` | Seconds a successful fetch's sizes remain fresh before the next lookup for that base URL triggers a refetch. |
| `failureTTL` | number (seconds) | `60` | Seconds a failed (including empty-parse) attempt's cache entry is honored before the next retry — shorter than `successTTL` so a down or non-Ollama server is checked again sooner without being fetched on every single lookup. |
| `model` | string | none — required per call | Passed to the size lookup; forwarded verbatim to the model server helper's size resolver, which additionally tries `model + ":latest"`. |
| `baseURL` | string | none — required per call | The OpenAI-compatible base URL (e.g. `http://localhost:11434/v1`) identifying the server; used both as the cache key and, via the native tags URL derivation, to derive the native tags URL to fetch. |

No environment variable, settings key, or feature flag configures this
component; it has no dependency beyond standard networking, and every
tunable is set at construction.

