
- **Data collected**: the twelve named provider credentials
  (`STATUS_CREDENTIAL_NAMES`), the `PEER_TOKEN` shared secret, the GitHub
  OAuth `clientId`/`clientSecret`, the two inbound webhook secrets, the
  admin-email allowlist, and — through `secrets` — any other
  environment-variable value the host exposes by name.
- **Storage**: none of these three files persists anything; the process
  environment itself (managed by the host's deployment platform, e.g.
  Railway's env store) is the storage, external to `env.ts`, `port.ts`, and
  `seed.ts`.
- **Transmission**: these three files never transmit a credential
  themselves; they hand a value by reference to whichever external caller
  presents it to a provider API (e.g. `github.clientSecret` used server-side
  by `status-server-auth`'s `exchangeCode`).
- **Retention**: no retention logic exists in these three files; a
  credential's lifetime is bounded by the host's own environment/secrets
  manager, not by anything here.

