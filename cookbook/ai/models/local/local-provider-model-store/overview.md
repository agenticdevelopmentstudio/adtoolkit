
The local provider model store is a **logic** component — no visual
surface — that gives a model chooser live model discovery for **local**
(loopback) OpenAI-compatible providers such as Ollama. Per the component's
own stated purpose: a local server's installed models are known only to
that server, so a fixed remote descriptor catalog can neither know what the
user pulled nor stay correct as models are pulled or removed; the store
instead lists a local server's models by asking it directly, caches the
last successful fetch per base URL so the chooser paints instantly and keeps
working while the server is down, and re-fetches on every rebuild to catch
changes. A second, independent responsibility — fetching per-model info —
batches per-model enrichment (a prose description, Ollama.com popularity
stats, and an Artificial Analysis leaderboard rank) from several live
sources into one call. Remote (non-loopback) providers are explicitly out
of scope for this component: per its own stated purpose, they "keep their
descriptor catalog," which this component does not touch.

