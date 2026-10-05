
The request specification is the value type a plugin's request-building
operation returns: a fully-described request for one chat turn. It carries
only a description of how the host should reach the provider — over HTTP or
by running a local command — plus a wall-clock timeout; it performs no
networking or process work itself. The plugin contributes the description;
the plugin transport is the sole consumer that turns the description into an
actual HTTP request or a subprocess. The split between transport kinds lives
in this type's transport-kind field, not in the plugin's identity, so every
plugin has the same "describe a request, decode the bytes" shape.

