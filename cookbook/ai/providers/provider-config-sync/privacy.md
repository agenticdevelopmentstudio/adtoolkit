
- **Data collected**: the resolved-configuration record's `secrets` field
  carries a provider credential (e.g. an API key) for every configuration
  that has one, alongside `values`' non-secret fields (e.g. a base URL).
  The sync envelope bundles every configuration's `secrets` together with
  `enabled` and `selectedConfigId` into one payload — this component's
  stated purpose is to move the app's full, already-resolved credential
  set to the daemon in one shot.
- **Storage**: this component performs no storage of its own (see
  `no-persistence`); per its documented contract, the receiving side is
  expected to persist each configuration "under the provider-configuration-keys
  component's namespace keyed by id" — plain settings keys for values, and
  a secure store for secrets — but no such receiver exists in this
  repository (see `sync-application-unimplemented`), so today nothing in
  this codebase actually stores a value carried by this type.
- **Transmission**: this component defines the payload's shape but
  performs no transmission itself; it is documented as crossing the
  app-to-daemon boundary (a process boundary, and per the
  provider-configuration-keys component's documented contract, potentially
  between the app's storage and "the daemon's registry"), but no sender
  exists in this repository either (see `sync-application-unimplemented`).
- **Retention**: the sync envelope and resolved-configuration record
  define no retention policy or expiry of their own; a constructed
  instance is a transient in-memory value with no cache. Any retention of
  the credentials it carries is entirely the responsibility of whatever
  (currently unimplemented) receiver persists them.
- **Disclosure safeguard**: Neither type overrides its default
  textual/debug description, so the compiler-synthesized default
  description of either type prints the entire `secrets` map — including
  any credential — verbatim; the types apply no redaction of their own.
  No caller in the given sources logs or prints a sync-envelope or
  resolved-configuration-record value today, so this has no live effect in
  this repository, but nothing in the type would stop a future caller from
  doing so.

