
Subsystem: `com.mikefullerton.agentictoolkit` | Category: client, registry

| Event | Level | Message |
|-------|-------|---------|
| A client's connect throws during the registry's reconcile step | error | "Failed to connect MCP server \(configuration.name): \(error.localizedDescription)" |
| The subprocess transport's connect completes its forwarding setup | debug | "Transport connected successfully" |
| The subprocess transport's disconnect finishes | debug | "Transport disconnected" |

The client itself has its own logger, but the given source contains no call site that emits through it directly — the capability exists without an observed emission in `MCPClient.swift`.

