
| Setting | Type | Default | Description |
|---------|------|---------|--------------|
| Maximum timer delay (milliseconds) | numeric constant | `2,147,483,647` | The signed 32-bit `setTimeout` ceiling in milliseconds (about 24.8 days) that every timer delay is clamped against. |
| Workspace-scan depth limit | numeric constant | `6` | How many directory levels deep the `workspaceContains:` scan descends before pruning. |
| Workspace-scan entry limit | numeric constant | `20,000` | The maximum number of file paths the workspace scan collects before stopping. |
| Skipped directory names | set of strings | `[".build", ".git", ".svn", ".venv", "DerivedData", "Pods", "__pycache__", "build", "dist", "node_modules", "target", "vendor"]` | Directory names the workspace scan never descends into. |
| File-system service | file-system-service role (required at init) | the shared production file-system service | The shared file-system service `vscode.workspace.fs` runs through across every host; defaulted so only a test supplies a double. |
| Ledger clock | a time-producing function | the system clock | The injected clock the ledger's first-access timestamp is stamped from, overridden in tests to make the first-stamp-is-kept rule assertable. |

