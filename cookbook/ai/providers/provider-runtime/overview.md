
The provider runtime is the non-UI logic root for talking to AI chat backends and discovering what models they offer. It has eight parts:

- the provider identity — identifies the five supported backends (`claudeCLI`, `anthropic`, `openai`, `google`, `custom`) and their display metadata (name, default models, recommended model, API-key placeholder, default base URL).
- the request configuration and builder — turns a provider selection and a message list into a provider-shaped HTTP request, and parses a provider's JSON reply or error body back into plain text.
- the model ranking store (backed by the Artificial Analysis leaderboard) — fetches and caches per-model intelligence/coding index rankings, and holds the API key that gates it.
- the local CLI runner — runs the local `claude -p` binary as a subprocess so a caller can get a model reply without an API key, reusing the user's existing Claude Code login.
- the model catalog store — fetches and merges prose model descriptions from OpenRouter, models.dev, and the adh provider-template catalog, then matches a bare or namespaced model id against them.
- the local model metadata store — asks a local Ollama server's native `/api/show` route what a pulled model can do and how big it is.
- the model page store — scrapes a model's `ollama.com` page for its author blurb and live popularity stats, the only place that prose exists for community fine-tunes.
- the model listing store (OpenAI-compatible) — lists the models an OpenAI-compatible `/models` endpoint actually serves.

All eight parts are pure logic with no rendering of their own and no dependency on a UI framework.

