
MCP Plumbing is the connection-lifecycle and reconciliation layer for the
Model Context Protocol: it turns a stored server configuration into a live,
tool-capable connection, keeps that connection's lifecycle safe under
concurrent connect/disconnect requests, and lets the host application itself
act as an in-process MCP server. It spans six files:

- `packages/apple/AgenticToolkit/Core/MCP/MCPClient.swift` — the client, its
  client-protocol surface, its connection-state type, and its error type. One
  instance owns one server's transport, its cached tool list, and the
  connect/disconnect race-safety documented on `teardown()`.
- `packages/apple/AgenticToolkit/Core/MCP/MCPServerConfiguration.swift` — the
  persisted, user-editable description of one server (a stdio command or an
  HTTP endpoint).
- `packages/apple/AgenticToolkit/Core/MCP/MCPServerRegistry.swift` — the
  registry that reconciles a set of live clients against the configurations
  and secrets the settings store reports, and exposes `tools(forIds:)` to
  callers assembling a tool list across servers.
- `packages/apple/AgenticToolkit/Core/MCP/MCPSettings.swift` — the settings
  declarations that route non-secret server descriptions to the regular
  settings provider and secret environment values to the secure (Keychain)
  provider.
- `packages/apple/AgenticToolkit/Core/MCP/SubprocessTransport.swift` — the
  subprocess transport, an implementation of MCP's own transport contract
  built on this codebase's shared subprocess-channel abstraction, used for
  every `.stdio` server instead of the MCP SDK's own stock stdio transport.
- `packages/apple/AgenticToolkit/macOS/Features/MCP/HostMCPServer.swift` — a
  self-contained in-process MCP server that exposes host
  application info and a "open a chat window" tool over an in-memory
  transport pair, with no subprocess and no registry integration.

