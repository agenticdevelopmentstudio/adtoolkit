
An AI plugin is the contract every AI provider plugin implements. A plugin
is the principal entry point of a plugin bundle: given one chat turn's
context, it describes the HTTP or subprocess request for that turn as a
request spec, and it creates a fresh stream decoder that turns the
provider's raw response bytes into stream events. A plugin never performs
networking, spawns a process, presents any UI, or stores a secret itself —
it only describes and decodes; the host performs the transport, builds the
settings UI from the bundle's descriptor schema, and owns secret storage.

