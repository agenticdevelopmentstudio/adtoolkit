
- **Data collected**: the given source collects no data of its own; `localResourceRoots` (file-system paths) and `extensionIdentifier` are carried through as opaque values, not inspected, logged, or transformed by this file.
- **Storage**: the given source performs no storage of its own; a panel's `state` string is held only in memory by whatever conforms to `ExtensionWebviewPanel` and is not persisted by this protocol.
- **Transmission**: the given source performs no network transmission of its own.
- **Retention**: the given source retains nothing beyond the lifetime of the panel handle itself.

