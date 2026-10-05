
- **Data handled**: Headers, body, standard input, and environment MAY each
  carry a credential a plugin has embedded into the request description —
  for example one provider plugin places an API key into an HTTP header,
  and a local-command plugin places the full process environment (which MAY
  contain secrets a shell session has exported) into a command
  specification's environment. This type itself has no knowledge of which
  fields hold a secret; it stores whatever byte payload or map value it is
  given.
- **Storage**: This type defines no storage of its own and MUST NOT persist
  any field to disk or any other durable store; per no-persistence, an
  instance exists only as long as the plugin and host both hold a reference
  to it during one chat turn.
- **Transmission**: A request specification never transmits data itself;
  its fields describe what the host's transport will send over HTTP or
  write to a subprocess's standard input, per host-http-consumption and
  host-command-consumption.
- **Violation handling**: Out of scope for this type — detecting or
  reacting to a leaked or invalid credential is the responsibility of the
  plugin that built the spec and the host's transport and secret-storage
  layers; this type performs no inspection of its own field values.

