
- **Empty base URL.** The size lookup with `baseURL: ""` MUST return
  nothing; the native tags URL derivation returns nothing, so no fetch is
  attempted and no cache entry is created (unresolvable-base-url-is-uncached).
- **Base URL that trims to empty.** A base URL such as `"/v1"` or `"///"`
  trims (via slash- and `/v1`-stripping) to an empty string inside the
  native tags URL derivation, which then returns nothing — the same
  unresolvable-base-url-is-uncached behavior as a literally empty base URL.
  MUST.
- **Empty model name.** The size lookup for an empty model name MUST return
  nothing unless the server's parsed sizes literally contain the empty
  string as a key (it never does in practice, since Ollama model names are
  non-empty) — ordinary miss behavior of the model server helper's size
  resolver, with no special-casing here.
- **TTL boundary.** An entry aged exactly the success TTL (or failure TTL)
  seconds MUST be treated as expired, not fresh, because the freshness check
  uses strict less-than, not less-than-or-equal (cache-freshness-window).
  MUST.
- **Concurrent access, single instance.** The catalog serializes distinct
  calls from different callers on the same instance at the statement level,
  with no possibility of a torn read or write of the cache. This is
  applicable — the shared instance is read from at least the inference
  guard, which itself runs from multiple callers — and is safe by
  construction for memory, but see
  concurrent-fetch-deduplication above and its Design Decision: statement-level safety does not
  prevent two concurrent callers for the same key from each triggering their
  own network fetch.
- **Server unreachable (network/offline).** When the local server's process
  is not running or the host is otherwise unreachable, the fetch fails with
  a connection failure (or any error from an injected fetch function); the
  per-server sizes lookup treats this exactly like any other failed attempt
  — fetch-throw-yields-no-data, then stale-while-error or never-known-stays-nil
  depending on prior cache state. MUST. There is no separate "offline" code
  path; connectivity loss is indistinguishable from any other fetch failure
  here.
- **Fetch timeout.** The built-in live fetch implementation's timeout is `5`
  seconds; a server that hangs past that bound causes a timeout failure,
  which is handled identically to any other failure
  (fetch-throw-yields-no-data). MUST.
- **Cancellation during a fetch.** If the calling operation is cancelled
  while the per-server sizes lookup is waiting on the fetch, no special
  handling applies: whatever error surfaces from that wait folds into the
  ordinary failure path exactly like any other failure, with no distinct
  "cancelled" outcome. MUST (this is the behavior, not a recommendation).
- **Non-Ollama local server (no `/api/tags`).** A local OpenAI-compatible
  server that isn't Ollama has no native tags endpoint; a request to the
  derived `/api/tags` URL either fails outright or returns a body the
  response parser cannot decode into any model entries. Either way the
  outcome folds into fetch-throw-yields-no-data or
  empty-parse-is-treated-as-failure; "non-Ollama server" is not
  special-cased against "Ollama server that's down." MUST.
- **Malformed or partially malformed `/api/tags` payload.** Garbage bytes
  (parsed to an empty set) and a payload where some model entries have the
  wrong field types (skipped individually) both flow through the catalog
  unchanged: a wholly malformed payload triggers
  empty-parse-is-treated-as-failure; a partially malformed payload yields
  whatever subset of sizes decoded successfully, which is cached and served
  as a normal success. MUST.

