
- **Data collected**: The manager reads plugin metadata only — a descriptor's identifier, display name, version, models, default model, fields (key/label/kind/placeholder shape, not values), and templates. It never reads, stores, or transmits a credential or configuration value; a field's secret kind only labels which *field* a settings UI should mask and persist to secure storage elsewhere in the plugin system — this component never touches an actual secret value.
- **Storage**: Everything this component reads is kept only in the in-memory records, loaded-plugins, and loaded-bundles collections (per `in-memory-state-only`); nothing is written to disk by this component.
- **Transmission**: This component performs no network communication.
- **Retention**: Discovered and loaded state lives only as long as the manager instance; it is not persisted and does not survive process restart.

