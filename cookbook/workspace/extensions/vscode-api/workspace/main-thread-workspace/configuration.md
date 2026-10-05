
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `workspaceRoots` | `ExtensionWorkspaceRoots?` | none (required, no default) | The workspace this bridge exposes through `name` and `workspaceFolders`, or null for "no workspace open." |
| `notImplementedLedger` | `NotImplementedLedger` | none (required, no default) | Where a reach for an undefined `vscode.workspace.fs` member is recorded, keyed by `extensionIdentifier` and member path. |
| `extensionIdentifier` | `String` | none (required, no default) | The extension this bridge belongs to, recorded alongside every `fs` ledger entry. |
| `fileSystemService` | `FileSystemServicing` | none (required, no default) | Where every `fs` operation actually reads and writes; MUST be the single instance shared across every extension's bridge, per **file-system-service-is-shared-not-per-extension**. |

