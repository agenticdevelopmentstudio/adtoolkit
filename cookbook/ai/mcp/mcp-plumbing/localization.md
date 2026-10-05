
The client's errors and the registry's log messages are hardcoded, unlocalized English strings with no string-catalog key, and the host MCP server's tool descriptions and tool-call bodies are likewise hardcoded English:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — literal, no catalog key) | "The MCP server was disabled or removed before its connection finished starting; nothing was launched." | The client's "already disconnected" error description |
| (none — literal, no catalog key) | "Failed to connect MCP server %@: %@" (interpolated with the configuration's name and the error's description) | The registry's reconcile failure log line |
| (none — literal, no catalog key) | "Return the host application's name, version, and configured AI plugins." | `host_app_info`'s tool description |
| (none — literal, no catalog key) | "Open a new AI chat window in the host application." | `host_open_chat_window`'s tool description |
| (none — literal, no catalog key) | "Host: %@\nVersion: %@\nPlugins: %@" | `host_app_info`'s success body |
| (none — literal, no catalog key) | "Opened a new chat window." | `host_open_chat_window`'s success body |
| (none — literal, no catalog key) | "Unknown tool: %@" | The unrecognized-tool-name default case body |

