
- **Data collected**: the plugin configuration's values conventionally
  carry a credential (`apiKey`) alongside non-secret configuration
  (`baseURL`, `model`, and any other plugin-declared field). Per its own
  documentation, the host is expected to have already "injected secrets
  (API keys) from secure storage" before constructing the value.
- **Storage**: this contract itself stores nothing durably — the plugin
  configuration is an in-memory value with no persistence of its own ("the
  plugin never touches storage itself," per its own documentation); the
  actual credential storage lives outside this contract, in whatever
  secure-storage mechanism the host uses.
- **Transmission**: this contract performs no transmission itself; the
  configuration's `apiKey`, if present, leaves the value's scope only when
  a plugin's request-building step reads it to build an outgoing request's
  headers or body.
- **Retention**: the chat context and the plugin configuration have no
  retention policy of their own — an instance is expected to be constructed
  fresh per request ("Everything a plugin needs to build one chat
  request," per its own documentation) and released once the request is
  built; nothing in this contract caches a value in a way that would
  extend a credential's in-memory lifetime beyond that.
- **Disclosure safeguard**: the plugin configuration provides no redacted
  description of itself, so a caller's default way of printing or logging
  one (or of a chat context containing one) would include the entire value
  dictionary, including any credential. No caller in this codebase logs or
  prints a chat context or plugin configuration value today (see Platform
  Notes for which files were checked), but this contract itself provides
  no protection against a future one doing so.

