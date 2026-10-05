
- **Data collected**: the resolver collects no data itself; it reads
  configuration identity (identifier, name, plugin identifier, template
  identifier) and a stored model string from whatever the caller's
  settings-reader function returns. No credential or secret value ever
  passes through this component — secret values are addressed by the
  provider-configuration-keys component and moved by the
  provider-configuration-sync and secret-store components, neither of
  which the resolver calls.
- **Storage**: the resolver performs no storage of its own; it only reads,
  through the caller-supplied function, whatever backing store the caller
  wraps (per the documented contract, a settings table).
- **Transmission**: this component performs no network transmission of
  its own; it only reads local, already-synced values.
- **Retention**: this component defines no retention policy; a value's
  lifetime is entirely the responsibility of the store behind the caller's
  settings function.

