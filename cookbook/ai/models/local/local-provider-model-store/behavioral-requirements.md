
- **loopback-detection**: The locality check MUST return the result of the
  model server helper's loopback detection unchanged — true only when the
  base URL's host, lowercased, is exactly one of `localhost`, `127.0.0.1`,
  `0.0.0.0`, `::1`, or `[::1]`, and false for any other host or for a base
  URL from which no host can be parsed.
- **page-stats-shape**: The page-stats structure MUST support being
  encoded, decoded, and compared for equality, and MUST hold a `downloads`
  field and an `updated` field, each independently optional — one MAY be
  present without the other.
- **per-baseurl-cache-scope**: The models cache (`aiplugin.localModelCache`,
  a map of base URL to an array of model ids) and the sizes cache
  (`aiplugin.localModelSizeCache`, a map of base URL to a map of model id to
  size in bytes) MUST be keyed by the exact base URL string passed to their
  respective fetch/cached operations, with no normalization of that key;
  the metadata cache (`aiplugin.localModelMetadataCache`, a map of base URL
  to a map of model id to metadata) MUST additionally nest by model id
  under each base URL.
- **global-cache-scope**: The description cache
  (`aiplugin.ollamaModelDescriptionCache`, a map of model id to description)
  and the page-stats cache (`aiplugin.ollamaModelPageStatsCache`, a map of
  model id to page stats) MUST be keyed by model id alone, shared globally
  across every base URL — two different servers that each expose a model of
  the same id share one cached description and one cached page-stats entry.
- **cached-accessors-are-pure-reads**: The cached-value accessors for
  models, sizes, metadata, descriptions, and page stats MUST read their
  respective cache synchronously, without making a network request, and
  MUST return an empty collection rather than nothing when no entry exists
  for the requested key.
- **models-endpoint**: The models fetch MUST strip at most one trailing
  slash from the base URL, MUST build the request URL by appending the
  literal path `/models` to the result, and MUST issue a `GET` request with
  a 5 second timeout.
- **models-fetch-success**: The models fetch MUST treat a response as
  successful only when the HTTP status is `200` and the body decodes as
  `{"data":[{"id": string}, ...]}` into a non-empty array of ids; on success
  it MUST replace the cached entry for the base URL with that id array and
  MUST return the same array.
- **models-fetch-failure**: The models fetch MUST return nothing, and MUST
  leave the cached entry for the base URL unchanged, for every other
  outcome: an unbuildable request URL, a failed request, a non-`200`
  status, an undecodable body, or a decoded-but-empty id array.
- **sizes-endpoint**: The sizes fetch MUST derive its request URL via the
  model server helper's native tags URL derivation (which strips all
  trailing slashes and one trailing `/v1` before appending `/api/tags`) and
  MUST issue a `GET` request with a 5 second timeout.
- **sizes-parse-tolerance**: The sizes fetch MUST parse a `200` response
  body with the model server helper's response parser, which decodes each
  `models[]` entry independently and skips one that fails to decode rather
  than discarding the whole response.
- **sizes-fetch-success**: When native tags URL derivation succeeds, the
  response is `200`, and the parsed sizes map is non-empty, the sizes fetch
  MUST replace the cached entry for the base URL with that map and MUST
  return it.
- **sizes-fetch-failure**: The sizes fetch MUST return nothing, and MUST
  leave the cached entry for the base URL unchanged, when native tags URL
  derivation returns nothing, the request fails, the status is not `200`,
  or the parsed sizes map is empty.
- **metadata-endpoint**: The metadata fetch MUST obtain metadata by calling
  a local model metadata store's fetch operation and MUST return nothing
  immediately, without modifying the metadata cache, when that call returns
  nothing.
- **metadata-merge-on-success**: On a successful result, the metadata fetch
  MUST merge the new model/metadata pair into the existing per-base-URL map
  (creating one if none exists) rather than replacing the whole
  per-base-URL map, so previously cached models under the same base URL
  MUST remain present.
- **model-info-sequential-order**: Fetching per-model info MUST wait for
  its three sources strictly in sequence — first the catalog description,
  then the leaderboard rank, then, only when the Ollama-page flag is true,
  the Ollama page fetch — never concurrently.
- **model-info-page-skipped**: When the Ollama-page flag is false, fetching
  per-model info MUST NOT call the Ollama page fetch, and the returned
  stats MUST be nothing.
- **description-precedence**: The description that fetching per-model info
  returns MUST be the page's description when the Ollama-page flag is
  true, the page fetch succeeded, the page description is present, AND it
  is judged substantial (at least 40 characters and containing a space);
  otherwise it MUST fall back to the catalog description whenever that is
  present.
- **description-non-substantial-fallback**: When the page description is
  present but not substantial and the catalog produced no description,
  fetching per-model info MUST return that non-substantial page description
  unchanged rather than discarding it.
- **description-cache-write**: Whenever fetching per-model info resolves a
  non-empty description, it MUST write it into the description cache under
  the model id, overwriting any previous entry for that model regardless of
  which base URL the call concerned.
- **stats-cache-write**: Fetching per-model info MUST write stats into the
  page-stats cache under the model id, and MUST return non-empty stats,
  only when the Ollama-page flag is true, the page fetch succeeded, and at
  least one of the page's downloads/updated fields is present; in every
  other case it MUST leave the page-stats cache for that model id unchanged
  and MUST return nothing for stats.
- **rank-independent-of-page**: Fetching per-model info MUST obtain and
  return the leaderboard rank regardless of the Ollama-page flag's value.
- **per-field-independent-nil**: Fetching per-model info's three returned
  fields (description, stats, rank) MUST each independently be empty when
  their own respective source failed or was skipped, without one field's
  failure affecting another's value.
- **no-request-coalescing**: The models fetch, sizes fetch, and metadata
  fetch MUST NOT deduplicate or join concurrent calls for the same key —
  unlike the catalog store's and the leaderboard store's in-flight-task
  coalescing pattern, each concurrent call to one of these three operations
  MUST perform its own network request.
- **serialized-atomic-cache-update**: The store MUST serialize its
  operations so that every read-modify-write of a cache map (read the
  current value, mutate the local copy, write it back) executes with no
  intervening suspension, so that two calls writing to *different* keys
  cannot interleave mid-update and lose one another's write.
- **cancellation-as-ordinary-failure**: The models fetch and sizes fetch
  MUST treat a cancellation signal from their wait exactly like any other
  failure — caught the same way, returning nothing and leaving the cache
  unmodified — with no distinct cancellation handling.
- **cache-persistence**: All five caches MUST persist through whichever
  settings store the shared settings instance routes to (a local key-value
  store by default) and MUST survive process restart for as long as that
  store retains the key.
- **cache-non-secure-storage**: The five cache declarations MUST NOT mark themselves secure; all five default to non-secure and are therefore held
  by the non-secure settings provider, never a credential-secured one.

One concern the component's own purpose calls for is not handled; it is stated below as current behavior and recorded as a pending Design Decision:

- **concurrent-fetch-deduplication**: The models, sizes and metadata fetch operations each read the current cache, wait on a network call, and only afterward write a new value back; because that wait is reentrant, two concurrent calls for the same base URL (or base URL and model pair) can both observe the same pre-fetch cache state and both issue their own request, and the cached value that survives is whichever call's write runs last, determined by network completion order rather than issue order. No in-flight-request tracking or coalescing exists.

A related behavior is a fact, not a gap:

- **fetch-error-is-fully-swallowed**: Every failure path in the models
  fetch, sizes fetch, metadata fetch, and the sources fetching per-model
  info calls into discards its error with no diagnostic, and none of them
  logs. A maintainer investigating why a local server's models stopped
  refreshing has no signal in this component distinguishing "server
  refused the connection" from "timed out" from "returned an undecodable
  body."
- **confines-to-ui-thread**: The component MUST be usable only on the UI thread.

