
- **Data collected**: Grant state only. The request operation for
  keychain reads the item's secret bytes solely to trigger the
  access-control dialog and discards them (**keychain-read-discards-bytes**);
  the location path reads authorization status, never coordinates.
- **Storage**: The keychain ledger stores `"granted"`/`"denied"` per
  service in the host's standard settings store; the key embeds the
  normalized service name. No secret is stored.
- **Transmission**: Nothing leaves the device.
- **Retention**: Ledger records persist until forgetting the service,
  recording undetermined for it, a read returning `errSecItemNotFound`,
  or removal of the app's persisted settings.

