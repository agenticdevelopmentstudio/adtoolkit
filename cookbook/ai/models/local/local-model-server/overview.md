
The model server helper is a **logic** component — no visual surface — a
stateless namespace holding four functions. Its purpose, stated directly by
its own documentation: it is shared by the inference guard and hosts' model
pickers so loopback detection, the native-API URL derivation, and
`/api/tags` size parsing cannot drift between call sites. Concretely, three
independent concerns that a local (loopback) OpenAI-compatible model server
touches are centralized here: (1) loopback detection decides whether a
configured base URL points at this machine; (2) native tags URL derivation
derives Ollama's native `/api/tags` listing URL from an OpenAI-compatible
base URL, because that native endpoint is the only one that reports a
model's on-disk size; (3) the response parser and size resolver decode that
endpoint's response into a model → size bytes map and look up one model in
it, tolerating the `:latest` shorthand. Direct callers include a
local-inference guard (loopback detection, to decide whether the guard
applies to a request), the model catalog and a local provider model store
(native tags URL derivation, response parsing, and size resolution, to
populate and query a model-size cache), and, one layer up the call chain, a
model-chooser settings surface. Unlike its stateful sibling the model
catalog (a time-to-live cache), the model server helper holds no state at
all beyond a fixed set of loopback host literals — every requirement below
is a pure function of its arguments, which is why this recipe is smaller
than a stateful sibling of the same family.

