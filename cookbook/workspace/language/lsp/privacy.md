
- **Data collected**: Per-server secret environment values (e.g. API keys a
  language server needs), stored in the persisted secrets setting, keyed by
  the configuration's id then environment-variable name
  (secrets-keyed-by-id-then-env-var). Non-secret configuration (command,
  arguments, non-secret environment, root markers) is not sensitive and is
  stored via the regular settings provider.
- **Storage**: Secrets are routed through secure storage, never the plain
  settings file (secrets-stored-in-keychain-not-plain-settings).
  Diagnostics held by the diagnostics store are in-memory only, keyed by
  document URI, and are never persisted to disk by this component.
- **Transmission**: A server's secret environment values are merged into
  its subprocess environment only at session start; this component never
  transmits them over the protocol channel itself — only the spawned
  process sees them, as environment variables
  (secrets-merged-into-environment-only-at-session-start).
- **Retention**: Diagnostics for a document are retained until the document
  is closed by its last editor (document-diagnostics-pruned-on-close) or
  until they are explicitly cleared or the store is shut down; secrets
  persist in secure storage until the user removes the configuration or
  changes the secret value.

