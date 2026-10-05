
- **Data collected**: this component collects no analytics of its own. It
  transports user-auth, sign-in-app, feature-flag, and server-bag records —
  configuration entities holding no end-user personal data — and storage-token
  records, which do carry a security-sensitive secret: the raw `adh_`-prefixed
  token minted by the create/mint operation.
- **Storage**: on the primary implementation, the revealed-secrets store holds the
  raw secret in an in-memory map on the topic instance only; it is never written to
  persistent storage or any file by this component. It is dropped by the revoke
  action and by the secret-expiry check on navigating away from the detail that
  revealed it. On the alternate client, the mint operation returns the
  created-token result to the caller with no persistence of any kind in that
  layer — the create-response body is the only response that carries the raw
  secret, and it is shown once.
- **Transmission**: the mint/create request travels over whichever transport the
  injected data source (primary implementation) or the equivalent
  authenticated-fetch helper (alternate client) implementation uses — neither is
  part of this component's given sources, and this component configures no TLS or
  transport-level behavior itself.
- **Retention**: the plaintext secret is retained only until the reveal-once
  contract expires it (primary implementation) or for as long as the caller holds
  the create response (alternate client; no retention logic is given). User-auth,
  sign-in-app, feature-flag, and server-bag records have no retention policy
  defined in these sources beyond whatever the backend itself enforces.

