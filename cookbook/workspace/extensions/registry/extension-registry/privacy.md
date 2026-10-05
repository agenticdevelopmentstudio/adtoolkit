
- **Data collected**: `ExtensionRegistry` reads only extension manifest metadata from disk — identifiers, versions, engine ranges, and `contributes.*` declarations — and the user's own set of disabled extension identifiers. It reads no credential, token, or other secret value; a manifest's own contents are third-party-authored text, not user-entered secrets.
- **Storage**: The only persisted state this file writes is `UserSettings.disabledExtensionIdentifiers` (a set of extension identifier strings) via `setEnabled`/`uninstall`. `extensions`, `failures`, and `contributionPoints` are in-memory only and are rebuilt from disk by every `loadAll()`/`reload()`.
- **Transmission**: Not applicable — this file performs no networking.
- **Retention**: `extensions` and `failures` live only as long as the `ExtensionRegistry` instance and are wholly replaced by each `apply(_:)`; `UserSettings.disabledExtensionIdentifiers` persists across launches until `uninstall(_:)` clears an identifier's tombstone or a user explicitly re-enables it.

