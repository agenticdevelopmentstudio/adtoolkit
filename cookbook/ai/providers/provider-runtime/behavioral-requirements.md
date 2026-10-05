
### Provider Identity

- **provider-identity**: The provider identity MUST be a fixed set of exactly five cases: `claudeCLI` (wire value `"claude_cli"`), `anthropic`, `openai`, `google`, `custom`, and MUST support iterating all cases and reading a stable per-case identity value.
- **provider-display-metadata**: Each case MUST expose a display name, default-models list, recommended model, a note about the recommendation, an API-key placeholder, and a default base URL, each a pure, non-throwing lookup with a value for every case (`custom` and `claudeCLI` return empty strings/lists where a fixed default has no meaning).
- **provider-cli-flag**: A "uses CLI" flag MUST be true only for the CLI provider, and a "requires API key" flag MUST be the logical negation of "uses CLI" — every non-CLI provider requires an API key, the CLI provider never does.
- **provider-safe-to-share**: Because the provider identity holds no reference state, a value MAY be read from any concurrent context; callers MUST NOT need to switch execution contexts just to read provider metadata.

### Request Configuration and Builder

- **request-config-shape**: The request configuration MUST carry exactly a provider selection, a model, an API key, a custom base URL, a max-tokens value, and a timeout interval, all supplied through its constructor.
- **request-config-isolation**: The request configuration MUST be treated as owned by a single caller and MUST NOT be shared across concurrent execution contexts without an explicit handoff — it stays confined to whichever caller constructed it (its current callers are a mini chat view model, a terminal session summarizer, and a settings view model).
- **request-dispatch-by-provider**: The builder MUST dispatch on the configured provider and build an Anthropic Messages request for `anthropic`, an OpenAI-compatible chat-completions request against the fixed `https://api.openai.com` base for `openai`, a Gemini `generateContent` request for `google`, and an OpenAI-compatible request against the configured custom base URL for `custom`.
- **request-custom-requires-base-url**: The builder MUST fail with a missing-base-url error when the provider is `custom` and no custom base URL is supplied, before attempting to build anything.
- **request-cli-provider-throws**: The builder MUST fail with an unsupported-provider error for the CLI provider rather than building an HTTP request — the CLI provider issues no network call from this layer, and callers MUST check whether a provider uses the CLI before ever calling the builder.
- **anthropic-request-shape**: The Anthropic builder MUST POST to `https://api.anthropic.com/v1/messages`, set `x-api-key` to the configured API key and `anthropic-version` to `"2023-06-01"`, default an empty model to `"claude-haiku-4-5-20251001"`, and include `system` in the body only when the system prompt is non-empty.
- **openai-compatible-request-shape**: The OpenAI-compatible builder (used for both `openai` and `custom`) MUST append `v1/chat/completions` to its base URL, set `Authorization: Bearer <apiKey>`, prepend a `system` message when the system prompt is non-empty, and default an empty model to `"gpt-4.1-nano"` for `openai` or leave it as supplied for `custom`.
- **openai-compatible-missing-url-throws**: The OpenAI-compatible builder MUST fail with a missing-base-url error when appending `v1/chat/completions` to the base URL does not yield a valid URL.
- **google-request-shape**: The Google builder MUST target `https://generativelanguage.googleapis.com/v1beta/models/<model>:generateContent?key=<apiKey>`, default an empty model to `"gemini-2.0-flash"`, remap any message whose role is `"assistant"` to Gemini's `"model"` role, and include `systemInstruction` in the body only when the system prompt is non-empty.
- **reply-parsing-by-provider**: Reply parsing MUST return `"(Unable to parse response)"` when the response body is not a JSON object, and otherwise MUST extract `content[0].text` for `anthropic`, `choices[0].message.content` for `openai` and `custom`, and `candidates[0].content.parts[0].text` for `google`.
- **reply-parsing-empty-fallback**: Reply parsing MUST return `"(Empty response)"` whenever the provider-specific shape is not found in an otherwise-parseable JSON object.
- **claude-cli-reply-parsing**: Reply parsing for the CLI provider MUST fall through to the generic `"(Empty response)"` fallback regardless of the response body: the source's CLI branch is an unfinished stub (marked with a `// todo: fix this` comment) that extracts nothing, so a CLI reply is never extracted by this parser.
- **error-message-extraction**: Error message extraction MUST prefer an `error.message` field, then a top-level `message` field, from a parseable JSON error body, and MUST fall back to `"HTTP <statusCode>"` when the body is not JSON or carries neither field.
- **request-builder-statelessness**: The builder holds no state of its own; none of its operations require confinement to a particular execution context, and it MAY be called from any context.

### Model Ranking (Artificial Analysis)

- **rank-store-isolation**: Mutations to the ranking store's state (the API key, the rank cache, the last-good result, and the in-flight fetch) MUST be serialized to a single execution context, so no two operations can race on them.
- **rank-model-shape**: A model-rank record MUST be equality-comparable and safe to share across concurrent contexts, and MUST carry a name, an intelligence index, a coding index, and an output-tokens-per-second figure, each numeric field optional.
- **rank-requires-api-key**: The store MUST report itself configured exactly when its stored API key is non-empty, and resolving a rank for a model MUST return no result, performing no network fetch, when the store is not configured.
- **rank-join-or-start**: Fetching all ranks MUST join an already-inflight fetch rather than starting a second one, so N concurrent callers resolving a rank in the same round trigger exactly one HTTP request.
- **rank-last-good-fallback**: When a fetch round returns an empty parse, fetching all ranks MUST fall back to the previous non-empty result rather than surfacing an empty leaderboard, and MUST update that fallback only from a non-empty result.
- **rank-per-model-persistence**: Resolving a rank for a model MUST persist a successfully matched rank into the rank cache keyed by the caller's original model id string, so cached ranks can paint a previously seen model instantly on reopen, before any live round completes.
- **rank-matching-reuse**: Resolving a rank for a model MUST resolve which leaderboard slug best matches the model using the model catalog store's best-match-key logic, the same conservative matching algorithm the description catalogs use — it MUST NOT implement a second matching algorithm.
- **rank-fetch-parse-purity**: Parsing and fetching the leaderboard data MUST be independent of the store's serialized state; parsing MUST be pure (no I/O, no shared-state mutation) and MUST skip any entry whose slug is missing or empty.
- **rank-fetch-degrades-to-nil**: Fetching leaderboard data MUST return no result — never throw — for any network failure, non-200 response, or malformed request, so a failed round degrades to an empty result inside "fetch all ranks" rather than propagating an error.

### Local CLI Runner

- **cli-binary-search-order**: Locating the CLI binary MUST search, in order, `~/.local/bin/claude`, `/usr/local/bin/claude`, `/opt/homebrew/bin/claude`, and MUST return the first path confirmed executable, or no result if none qualify.
- **cli-binary-missing-throws**: Running the CLI MUST fail with a binary-not-found error before spawning anything when no binary can be located.
- **cli-argument-shape**: Running the CLI MUST invoke the resolved binary with `-p --system-prompt <systemPrompt>`, and MUST append `--model <model>` only when a model is non-empty, leaving the CLI's own default model selection intact otherwise.
- **cli-path-augmentation**: Running the CLI MUST prepend `~/.local/bin`, `/usr/local/bin`, and `/opt/homebrew/bin` to the child process's inherited `PATH` environment variable before launch.
- **cli-headless-marker**: Running the CLI MUST set `AGENTIC_TOOLKIT_HEADLESS=1` in the child's environment so an inherited session-tracking hook can identify this as a programmatic invocation rather than a real interactive session.
- **cli-launch-failure**: Running the CLI MUST catch a failure to launch the process and re-surface it as a launch-failed error carrying the underlying failure's description, never letting the underlying error type escape.
- **cli-stdin-write-non-fatal**: Running the CLI MUST write the prompt to the child's standard input and close it, and MUST treat a write failure (child already exited) as non-fatal — it MUST proceed to read whatever the child emitted rather than failing the call.
- **cli-concurrent-drain**: Running the CLI MUST read the child's standard output and standard error streams concurrently with waiting for exit, never sequentially, to avoid deadlocking against a child that fills a stream buffer (~64KB) before draining starts.
- **cli-wait-off-async-scheduler**: Running the CLI MUST perform the blocking wait-for-exit call off whatever asynchronous scheduling pool the runtime's own concurrency depends on, since that wait call blocks its calling thread.
- **cli-timeout-terminates**: Running the CLI MUST start a timeout that, once elapsed, terminates the process if it is still running, and MUST cancel that timeout once the process has exited.
- **cli-nonzero-exit-throws**: Running the CLI MUST fail with a non-zero-exit error carrying the exit code and captured stderr when the process's termination status is non-zero, truncating the reported stderr to its first 200 characters.
- **cli-empty-reply-throws**: Running the CLI MUST fail with an empty-reply error when the trimmed standard output is empty on a zero exit status.
- **cli-error-safe-to-share**: Every CLI error case MUST be safe to share across concurrent contexts and MUST supply a non-nil description for every case.

### Model Catalog

- **catalog-store-isolation**: Mutations to the catalog store's stateful surface (fetching the catalog, the last-good result, the in-flight fetch) MUST be serialized to a single execution context, while its pure helpers (merging, substantiality checks, the per-source parsers, best-match resolution, and the raw fetch) MUST be independent of that context so they can run anywhere.
- **catalog-shape**: A catalog value MUST be safe to share across concurrent contexts and MUST carry independent OpenRouter, models.dev, and adh maps (each a string-to-string mapping), with emptiness true only when all three are empty.
- **catalog-join-or-start**: Fetching the catalog MUST join an already-inflight fetch rather than starting a second one, so N concurrent callers trigger exactly one three-way network round.
- **catalog-concurrent-fetch**: Fetching the catalog MUST fetch OpenRouter, models.dev, and the adh endpoint concurrently, not sequentially.
- **catalog-per-side-fallback**: Merging a fresh result with the last-good result MUST replace only the sides of the fresh result that are empty with the corresponding side of the last-good result, and MUST leave a successfully fetched side untouched even when its sibling sides failed — one side's failure MUST NOT blank another side's data nor poison the last-good result with a half-empty round.
- **catalog-description-priority**: Looking up a description MUST try the adh catalog first, then OpenRouter, then models.dev, returning the first confident match — the adh catalog is the curated, operator-authored source and takes priority over the third-party catalogs.
- **catalog-adh-url-mutable**: The adh catalog URL MUST be a mutable, process-wide value (not fixed), defaulting to `"https://api.agenticdeveloperhub.com/persona/provider-templates?pageSize=100"`; it fetches a single page capped at `pageSize=100` and does not paginate through `total`.
- **openrouter-parse-skips-empty**: Parsing the OpenRouter catalog MUST map `data[].id` to `data[].description` and MUST skip any entry with a missing id or a missing/empty description.
- **modelsdev-parse-first-provider-wins**: Parsing the models.dev catalog MUST iterate providers in sorted key order and MUST keep the first provider's description for a given model id, ignoring later providers' descriptions of the same id.
- **adh-parse-skips-empty**: Parsing the adh catalog MUST map each catalog item's `models[].name` to `models[].description`, skipping entries with a missing/empty description or a name already claimed by an earlier item.
- **best-match-prefix-anchored**: Best-match resolution MUST require a candidate's last path segment, normalized to lowercase ASCII alphanumerics, to start with the model's normalized base name — a candidate that merely contains the base name MUST NOT match.
- **best-match-size-restriction**: When the queried model carries a parameter-size tag (e.g. `:8b`), matching MUST restrict to candidates sharing that exact size token when any exist, otherwise to size-less (family-level) candidates, and MUST NEVER match a candidate carrying a different size token.
- **best-match-shortest-wins**: Among qualifying candidates, best-match resolution MUST prefer the one with the shortest normalized id, then the lexicographically first raw key, as a deterministic tiebreaker.
- **best-match-latest-retry**: Best-match resolution MUST retry the match with a trailing `"latest"` suffix stripped from the model's normalized base name when the first attempt fails and the base name is not itself exactly `"latest"`.
- **best-match-degenerate-inputs**: Best-match resolution MUST return no match for an empty model name, a model name whose base segment is empty (e.g. `":16b"`), or an empty candidate list — never throw or crash.
- **substantiality-threshold**: A substantiality check MUST require at least 40 characters AND at least one space character before a fetched description is allowed to satisfy the catalog fallback.
- **catalog-fetch-degrades-to-nil**: The raw catalog fetch MUST return no result — never throw — for any network failure, non-200 response, or unparseable URL string.

### Local Model Metadata

- **ollama-metadata-shape**: A local model metadata record MUST be equality-comparable and safe to share across concurrent contexts, and MUST carry capabilities, parameter size, quantization, and context length, with tool-support and vision-support flags derived from whether capabilities contains `"tools"`/`"vision"`.
- **loopback-detection**: Determining whether a base URL is a loopback address MUST return true only when the URL's host, lowercased, is one of `localhost`, `127.0.0.1`, `0.0.0.0`, `::1`, or `[::1]`, and false for any other host including a malformed URL.
- **native-base-derivation**: Deriving the native API base from an OpenAI-compatible base URL MUST strip trailing slashes and, if present, a trailing `/v1` segment (plus any further trailing slashes), to reach Ollama's native API root.
- **show-parse-requires-signal**: Parsing a model-info response MUST return no result when the body is not a JSON object or when capabilities is empty AND parameter size, quantization, and context length are all absent — a response carrying nothing useful MUST NOT produce a metadata value.
- **show-parse-context-length-key**: Parsing MUST locate the context length by scanning the model-info payload for the first key ending in `.context_length`, accepting either an integer or a floating-point JSON value for it.
- **metadata-fetch-degrades-to-nil**: Fetching metadata MUST return no result — never throw — when the derived native base is empty, the URL/body fails to construct, the request fails, or the response is not a 200.
- **metadata-store-statelessness**: The local model metadata store holds no mutable state of its own; none of its operations require confinement to a particular execution context.

### Model Page Info

- **page-info-shape**: A page-info record MUST be equality-comparable and safe to share across concurrent contexts, and MUST carry optional description, downloads, and updated fields, with emptiness true only when all three are absent.
- **page-url-routing**: Building a page URL MUST drop any `:tag` suffix from the model id, route a bare name to `https://ollama.com/library/<name>`, and route a `namespace/name` id to `https://ollama.com/<namespace>/<name>`.
- **page-url-rejects-malformed**: Building a page URL MUST return no result for an empty model id, or one whose name segment starts with `/` or ends with `/`.
- **description-parse-priority**: Parsing the description MUST prefer an `og:description` meta tag (in either attribute order) over a plain `name="description"` meta tag, MUST entity-unescape the captured text (`&amp;` decoded last, so `&amp;lt;` yields `&lt;` rather than `<`), and MUST return no result when the trimmed text is empty or no matching tag exists.
- **stats-parse-independent-fields**: Parsing stats MUST extract downloads and updated independently via separate matching passes, and MUST return no value for either field whose markup is absent, without requiring the other field to be present.
- **page-fetch-degrades-to-nil**: Fetching page info MUST return no result — never throw — when the page URL fails to construct, the request fails, the response is not a 200, or the body cannot be decoded as text.
- **page-store-statelessness**: The model page store holds no mutable state of its own; none of its operations require confinement to a particular execution context.

### Model Listing (OpenAI-Compatible)

- **catalog-fetch-shape**: Fetching the model listing MUST append `models` as a path component to the trimmed base URL, and MUST set `Authorization: Bearer <apiKey>` only when a non-empty API key is supplied.
- **catalog-fetch-degrades-to-empty**: Fetching the model listing MUST return an empty list — never throw — when the base URL is empty or unparseable, the request fails, or the response status is outside `200..<300`.
- **catalog-parse-shape**: Parsing the model listing MUST extract `data[].id` from an OpenAI-shaped `/models` JSON body, silently dropping any entry without a string id, and MUST return an empty list for a non-JSON body or a body without a `data` array.
- **model-catalog-statelessness**: The model listing store holds no mutable state of its own; none of its operations require confinement to a particular execution context.

### Security

- **api-key-in-memory-only-scope**: The API key and custom base URL held by the request configuration MUST be understood as caller-supplied, in-memory values for the duration of one request — this component itself performs no persistence of them; responsibility for how they were obtained and stored belongs to the caller (a chat view model, a terminal summarizer, or a settings view model).
- **artificial-analysis-key-storage**: The API key and rank cache backing the model ranking store MUST be persisted via the plain settings store rather than the secure credential store — this is a genuine, unmitigated plaintext-storage fact about the shipped code, not a hypothetical (see Platform Notes for the storage mechanism this maps to).
- **google-key-in-url**: The Google request builder MUST place the configured API key directly in the request URL's query string (`?key=<apiKey>`) per the Gemini API's documented contract — callers and any request-logging infrastructure downstream of this component MUST treat that URL as key-bearing.
- **custom-endpoint-scheme-validation**: The request builder's OpenAI-compatible path (for the custom provider's base URL), the model listing store's fetch, and the local model metadata store's fetch MUST use the supplied base URL as given, performing no URL scheme validation; an operator-supplied `http://` endpoint therefore carries its `Authorization: Bearer <apiKey>` header in plaintext, with no guard anywhere in this component.

