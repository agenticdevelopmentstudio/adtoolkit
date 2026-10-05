
- **Data collected**: this component collects no data itself; it computes
  the *names* (storage keys) under which a configuration's field values —
  including a provider credential when a descriptor field is marked secret
  (e.g. an API key) — are looked up. The credential value itself never
  passes through this component.
- **Storage**: this component performs no storage of its own. The key it
  returns for a secret field is used as-is by the caller's secure backing
  store on the app side, or by the secret-storing component on the daemon
  side. Non-secret fields and the four registry-level constants are stored
  by whatever settings store the caller passes as its settings-reader.
- **Transmission**: this component performs no network transmission.
  Whether a secret crosses the app-daemon boundary at all is determined by
  the provider-configuration sync component, a different component; this
  component only supplies the address both sides use to store the resolved
  value locally.
- **Retention**: this component defines no retention policy or expiry; a
  key's value persists for as long as the caller's backing store keeps it.
  Removal is the caller's responsibility — the app-side configuration store
  resets non-secret fields and the model to an empty string (clearing the
  effective secure-store entry when the field is marked secure); whether
  the daemon-side secret-fields-key/fields-key ledgers drive an equivalent
  removal is the gap recorded under `secret-fields-key-consumer` and its Design Decision.

