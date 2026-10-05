
The local model catalog is a **logic** component — no visual surface — that
resolves the on-disk size, in bytes, of a model hosted by a local model
server, so a caller such as the inference guard can weigh a model's
footprint against the machine's RAM budget before allowing it to load. A
model server exposes no size information over the OpenAI-compatible `/v1`
surface most gateways speak; Ollama's own native `/api/tags` listing is the
only one that reports a `size` per model, so the catalog derives that native
URL from the caller's OpenAI-compatible base URL (via the model server
helper's native tags URL derivation), fetches and parses it (the model
server helper's response parser), and looks up one model's size (the model
server helper's size resolver, which tolerates the `:latest` shorthand).
Because that fetch is a network round trip with real per-call cost — and the
guard runs ahead of every local-model request — results are cached per base
URL with independent time-to-live windows for success (`successTTL`, default
300 seconds) and failure (`failureTTL`, default 60 seconds): a down or
non-Ollama server is retried on a slower cadence than a healthy one, and a
failed refetch never discards a server's last known-good sizes — stale sizes
still serve the guard, because a model already known to be over budget must
never be forgotten just because the server is momentarily busy or
unreachable. One shared, process-wide instance is available for callers that
do not construct their own; the inference guard defaults to it when
constructed without an explicit catalog.

