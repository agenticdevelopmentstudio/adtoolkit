
A plugin descriptor is the host-side model of a plugin's `descriptor.json`:
its identity, the models it offers, and the settings fields the host should
render and persist. A plugin ships this as a plain JSON resource inside its
plugin bundle. The host reads it at plugin *discovery* time — before, and
without ever, loading the plugin's compiled code — so a host UI can list and
configure a provider from data alone. All presentation and configuration
metadata lives here as data; the plugin's own compiled contract contributes
only request-building and response-decoding. The descriptor defines four
value types: the descriptor itself, a field (one configurable value),
per-model detail (optional per-model metadata), and a provider template (a
named provider preset). None of the four performs I/O; the descriptor's only
"operations" are pure resolution helpers (resolving a default model,
resolving templates, resolving fields for a template, looking up per-model
detail) over already-decoded data.

