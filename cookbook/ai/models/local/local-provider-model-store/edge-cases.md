
- **Null and empty input**: An empty base URL passed to the models fetch
  yields a trimmed empty string, and the relative path `/models` still
  parses successfully as a schemeless relative URL, so the request is
  attempted and fails at the transport layer (folds into
  models-fetch-failure), MUST. An empty base URL passed to the sizes fetch
  or metadata fetch (via native tags URL derivation / the metadata store's
  own base-URL derivation) trims to empty and yields no usable URL before
  any request is made, MUST. An empty model string is not special-cased
  anywhere in this component — it is forwarded verbatim to the metadata
  store's fetch, the Ollama page lookup (which returns nothing for an empty
  name), and the catalog description / leaderboard rank lookups (which
  fail their internal matching), so fetching model info for an empty model
  resolves every field to whatever its collaborator returns for an empty
  id — typically all empty — with no explicit empty-string guard.
- **Boundary values**: A base URL with exactly one trailing slash is
  stripped correctly by the models fetch; a base URL with two or more
  trailing slashes has only one removed, so the request URL ends up with an
  embedded double slash before `/models` — a direct, undocumented
  consequence of the single (not looping) strip, unlike native tags URL
  derivation's loop, which strips all of them. This recipe records that
  divergence rather than assuming both operations normalize identically
  (see Design Decisions).
- **Concurrent access**: The store serializes its operations, so calls
  interleave only at defined suspension points; a single call's own
  read-modify-write of a cache map is never split across a suspension
  point, so writes to *different* keys never corrupt or lose one another
  (MUST, see serialized-atomic-cache-update). Two *concurrent* calls for
  the *same* key are not deduplicated and race on which one's result is
  cached last (MUST NOT deduplicate, see no-request-coalescing; final value
  undefined, see **concurrent-fetch-deduplication**).
- **Error states**: Every network failure — a bad URL, a failed request, a
  non-`200` status, an undecodable body, or (for the sizes fetch) a parse
  that yields no entries — is treated identically: the affected operation
  returns nothing and its cache entry is left exactly as it was (MUST, see
  models-fetch-failure, sizes-fetch-failure, metadata-endpoint). None of
  these paths logs, raises to the caller, or otherwise signals which
  specific failure occurred — see fetch-error-is-fully-swallowed in
  Behavioral Requirements.
- **Offline or disconnected state**: When the target base URL server is
  unreachable (process not running, host down), every direct request in
  this component (`/models`, the derived `/api/tags`, and, via the metadata
  fetch, the derived `/api/show`) fails with a transport failure that is
  caught and folded into the ordinary failure path above; callers are
  expected to keep rendering cached models/sizes/metadata for that base
  URL in the meantime, per the component's own stated purpose ("keeps
  working when the server is down"), MUST.
- **Cancellation and timeouts**: The models fetch and sizes fetch bound
  their own request to a `5`-second timeout; a timeout is an ordinary
  failure caught the same way as any other transport failure (MUST, see
  cancellation-as-ordinary-failure). Cancellation during any of the waits
  inside fetching model info (the catalog, rank, or page call) is not
  special-cased in this component; whatever each collaborator returns for
  a cancelled call (typically empty, per each collaborator's own
  degrade-to-empty contract) flows through unchanged.
- **Missing file or unreachable server**: Not applicable as a distinct
  code path — a local server process that has quit, or one that is running
  but is not Ollama (so `/api/tags`/`/api/show` don't exist), is
  indistinguishable in this component from any other transport failure or
  non-`200`/undecodable response; see Error states above.

