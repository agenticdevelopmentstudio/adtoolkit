
- **Data collected**: a plaintext bearer secret (the created-token result's `token`
  field) is returned exactly once, in the response to a successful create-token
  operation.
- **Storage**: the applications topic never persists the secret; the revealed-secrets
  store is an in-memory key-value map on the topic instance, with no file,
  user-defaults, or keychain write anywhere in this component.
- **Transmission**: this component never transmits the secret itself — it receives it
  once from the create-token response and places it into a read-only form field for
  on-screen display; actual network transmission is the injected data source's
  concern, out of scope of this component.
- **Retention**: bounded by two independent mechanisms — the reveal-once rule
  (**token-secret-expires-on-navigation**), which drops the secret from the
  revealed-secrets store the moment navigation moves away from that token's detail,
  and the applications topic instance's own lifetime (the store holds nothing once
  the instance is deallocated).
- **Disclosure safeguard**: the created-token result — the one type that carries a
  raw plaintext secret in its `token` field — has no custom string-description
  override, so its default, naive description would include the secret in full if
  ever logged or printed. The applications topic never logs or prints a created-token
  value; it stores only its `token` field into the revealed-secrets store. A port
  MUST NOT log this value.

