
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `command` | string | none (caller-supplied) | Absolute path to the server executable, e.g. `/usr/bin/sourcekit-lsp` |
| `languageIds` | array of strings | none (caller-supplied) | LSP language ids this server serves, e.g. `["swift"]` |
| `arguments` | array of strings | `[]` | Process arguments passed to `command` |
| `environment` | key-value map | `{}` | Non-secret environment overrides merged over the parent environment |
| `rootMarkers` | array of strings | `[".git"]` | File/directory names, most specific first, that mark a workspace root; supports glob-suffix markers like `*.xcodeproj` |
| `isEnabled` | boolean | `true` | Whether the registry starts/keeps a session for this configuration |
| Persisted server-configurations list | array of configurations | `[]` | Persisted key `languageServer.serverConfigurations` |
| Persisted server-secrets store | secrets map, routed through secure storage | `{}` | Persisted key `languageServer.serverSecrets`, keyed by the configuration's id then env-var name |
| Handshake budget | seconds | `30` | Wall-clock budget for the `initialize` handshake |
| Graceful-shutdown budget | seconds | `2` | Wall-clock budget for the graceful shutdown/exit round trip |
| Abandoned-start budget | seconds | `1` | Wall-clock budget teardown waits for an in-flight start to abandon |
| Outstanding-request budget | seconds | `2` | Wall-clock budget teardown waits for outstanding requests to finish |
| Exit-status budget | seconds | `1` | Wall-clock budget teardown waits for the process exit status |
| Built-in configurations | one fixed entry | SourceKit-LSP, fixed identifier `1CE31A0E-0000-4000-A000-5357494654FF` | Ships regardless of user configuration; overridden per-language by a matching user configuration |

