
- **Data collected**: No personal or account data. The store transmits a
  model id string to Ollama.com's public model page (fetching model info
  when the Ollama-page flag is true, via the Ollama page lookup) and to the
  caller-supplied base URL (a user-configured local/loopback server) for
  the `/models`, `/api/tags`, and `/api/show` lookups. Fetching model info
  also triggers its collaborators the catalog store (openrouter.ai,
  models.dev, and the ADH catalog endpoint) and the leaderboard store
  (artificialanalysis.ai, which attaches any user-stored API key as an
  `x-api-key` header) — those requests originate inside those collaborator
  components, not this one, but are triggered by this component's call.
- **Storage**: Cached values (model ids, byte sizes, metadata, free-text
  descriptions, page stats) persist on-device through the five persisted
  keys listed under Configuration, via the default (non-secure) settings
  provider; none is marked secure.
- **Transmission**: Plain HTTP(S) `GET` requests to `{baseURL}/models`, the
  derived `.../api/tags`, and Ollama.com's model page; one HTTP(S) `POST` to
  the derived `.../api/show` with a small JSON body (`{"model": <model>}`).
  No request in this component carries a credential or token.
- **Retention**: Cached values are retained indefinitely — this component
  provides no explicit clear, remove, or expiry operation for any of its
  five caches. A value is only ever replaced by a later successful fetch
  for the same key, or removed if the underlying settings store is cleared
  externally.

