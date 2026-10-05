
- **No model-ranking API key configured**: resolving a rank for a model MUST return no result immediately and MUST NOT perform any network request when the model ranking store is not configured.
- **Empty custom base URL**: the request builder MUST fail with a missing-base-url error for a `custom` provider whose custom base URL is empty, rather than attempting to build a request against an empty string.
- **Size-tag boundary mismatch**: best-match resolution MUST NEVER match a model carrying one parameter-size tag (e.g. `4b`) against a catalog candidate carrying a different one (e.g. `24b`), even when every other token matches.
- **Concurrent catalog/rank requests**: N concurrent callers fetching the catalog or resolving ranks within the same round MUST result in exactly one network round-trip per source, joined via the shared in-flight fetch, never N independent round-trips.
- **All-source network failure**: When every one of OpenRouter, models.dev, and the adh endpoint fails in the same round, fetching the catalog MUST return the previous last-good result (or an empty catalog if none exists yet) rather than throwing.
- **CLI binary absent**: running the CLI MUST fail with a binary-not-found error when none of the three candidate paths is an executable file, and MUST NOT attempt to spawn a process.
- **CLI non-zero exit or timeout**: running the CLI MUST fail with a non-zero-exit error on a non-zero termination status, and SHOULD terminate a hung child once the caller-supplied timeout elapses.
- **Broken pipe writing to the CLI's standard input**: running the CLI MUST treat a failed standard-input write (child exited before reading) as non-fatal and MUST proceed to read whatever the child already emitted, rather than propagating the write error.
- **Malformed/garbage JSON everywhere**: every parsing function in this component (the per-source catalog parsers, the ranking parser, the model-info parser, the model-listing parser, the reply parser) MUST return an empty/no result for non-JSON or structurally unexpected input, and MUST NOT throw or crash.
- **Ollama page markup partially present**: parsing stats MUST return a result whose downloads and updated fields are independently absent when only one of the two markup patterns is present, rather than requiring both or neither.

