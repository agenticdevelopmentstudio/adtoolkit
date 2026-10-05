
- **Data collected**: the secret store keeps exactly the caller-supplied
  value under key — in this framework's one production call path, an AI
  provider credential (e.g. an API key) addressed by a provider
  configuration's field-key operation. Neither the interface nor the
  production implementation inspects, parses, or interprets the content of
  value; it is handled as an opaque secret throughout.
- **Storage**: the production implementation stores value as a secure
  credential item via the platform's secure-storage helper, scoped to the
  active service identifier (and, when set, the shared-storage access
  group); the operating system's secure store provides the actual
  encryption-at-rest and access control — this component itself performs
  no additional encryption or obfuscation.
- **Transmission**: this component performs no network transmission of its
  own.
- **Retention**: a stored secret persists in the secure store until a
  caller explicitly calls delete or delete-legacy, or until it is removed
  outside this component (e.g. the platform's own credential-management
  interface, an OS reset); the source defines no time-to-live, expiry, or
  automatic revocation. The secret store performs no verification of
  caller authorization beyond what the OS-level secure store and any
  platform access-control entitlement already enforce, and detects no
  misuse of a stored secret — it raises no signal when a credential is used
  out of its intended context.

