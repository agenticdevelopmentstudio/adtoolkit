
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `presenter` | a presenter | none (required) | Puts a `createWebviewPanel` request on screen, or answers nothing when no window is open. |
| `notImplementedLedger` | a shared not-implemented ledger | none (required) | Shared record of every webview member this host reaches for but does not honor. |
| `extensionIdentifier` | a string | none (required) | The extension this adaptor instance belongs to; stamped on every ledger row and error log line. |
| `extensionDirectory` | a file location | none (required) | This extension's install directory; the first entry in the default `localResourceRoots`. |
| `workspaceRoots` | a workspace roots provider (optional) | none (required, nullable) | Read fresh on every `createWebviewPanel` call to append the open project's folders to the default resource roots; absent when there is no workspace concept for this host. |

