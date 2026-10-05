
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `configuration` (parameter to constructing a client) | `MCPServerConfiguration` | none — required | The server this client connects to: its transport, name, and id. |
| `secrets` (parameter to constructing a client) | `[String: String]` | `[:]` | Secret environment values merged over the configuration's own environment for a `.stdio` server, per secrets-override-environment. |
| `clientName` (parameter to constructing a client) | `String` | `"AgenticToolkit"` | The name this client presents to the MCP server during initialization. |
| `clientVersion` (parameter to constructing a client) | `String` | `"1.0.0"` | The version this client presents to the MCP server during initialization. |
| `store` (parameter to constructing the registry) | `SettingsStore` | none — required | Source of the server-configurations and server-secrets settings the registry reconciles against. |
| `clientFactory` (parameter to constructing the registry) | `ClientFactory` (a function, invoked on the UI thread, from a server configuration and a string-to-string secrets map to an MCP client) | Constructs a real client from a server configuration and its secrets | Lets a caller substitute a test double; production code accepts the default. |
| `mcp.serverConfigurations` (settings key) | `[MCPServerConfiguration]` | `[]` | Non-secret server descriptions, routed to the regular settings provider. |
| `mcp.serverSecrets` (settings key) | `MCPServerSecrets` (`[String: [String: String]]`) | `[:]` | Secret environment values keyed by server id, routed to the secure (Keychain) settings provider. |
| `logger` (parameter to constructing the subprocess transport) | `Logger?` | `nil` (a no-op logger) | Diagnostic logger for the transport's own debug messages; production code does not supply one. |
| `appName`, `appVersion` (parameters to constructing the host MCP server) | `String` | none — required | Reported by the `host_app_info` tool. |
| `pluginNames` (parameter to constructing the host MCP server) | `[String]` | `[]` | Reported by the `host_app_info` tool, joined by `", "` or rendered as `(none)` when empty. |
| `openChatWindow` (parameter to constructing the host MCP server) | a shareable callback taking no arguments and returning nothing | a no-op callback | Invoked when the `host_open_chat_window` tool is called. |
| `abandonedConnectBudgetSeconds` (a fixed constant owned by the client) | `TimeInterval` | `1.0` | Fixed wall-clock bound teardown gives an in-flight connect before abandoning it; not exposed to callers. |

