
- **Data collected**: Provider credentials and connection settings the user
  enters for a configuration — secret fields (e.g. an `apiKey`, a secret
  kind) and plain fields (e.g. a `baseURL`, a plain-text kind), plus the
  chosen model — are the sensitive data this component stores and resolves.
  Resolved configuration values are explicitly documented as "secrets
  included."
- **Storage**: A field's secret kind routes its persisted setting to be
  marked secure, which stores it in secure storage rather than plain
  settings; a plain-text field is persisted to the plain (non-secure)
  settings store. Setting a secret field's value to "" (clearing stored
  values) removes it from secure storage.
- **Transmission**: This component never performs network I/O itself. It
  assembles the resolved value bag into a configuration bag inside a chat
  request context and hands that to the selected plugin's request-building
  operation; the plugin (outside this component's given sources) decides
  which of those values, including any secret, become part of the outgoing
  request that the plugin transport then performs.
- **Retention**: Stored field/model values persist indefinitely (secure
  storage for secrets, plain settings for the rest) until clearing stored
  values is called for that configuration — there is no expiry, rotation, or
  time-based invalidation logic anywhere in this component; a stored value is
  valid until explicitly overwritten or cleared.

