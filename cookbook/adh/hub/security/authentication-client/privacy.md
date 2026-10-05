
- **Data collected**: a plaintext bearer secret is returned exactly once, in the response to a
  successful create call.
- **Storage**: none of the four roles persists the secret; the revealed-secrets store is an in-memory
  mapping owned by the rail instance, with no file, settings-store, or secure-credential-store write
  anywhere in this component.
- **Transmission**: this component never transmits the secret itself — it receives it once from the
  create response and places it into a read-only field for on-screen display; actual network
  transmission is the injected data source's concern, out of scope of these roles.
- **Retention**: bounded by two independent mechanisms — the reveal-once rule
  (`security-secret-single-source`), which drops a secret from the revealed-secrets store the moment
  navigation moves away from its detail, and the instance's own lifetime (the store holds nothing once
  the instance goes away, e.g. on app relaunch).
- **Disclosure safeguard**: the two wire shapes that carry a raw plaintext secret in their `token`
  field declare no custom string-conversion override, so their default description includes the secret
  in full. Neither rail logs or prints the create-response value; both store only its secret into the
  revealed-secrets map. A port MUST NOT log these values.

