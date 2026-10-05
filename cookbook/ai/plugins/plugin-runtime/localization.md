
None of the given sources route their user-facing strings through a
localization mechanism; they are hardcoded English literals, listed here as
facts rather than as a marker per source fidelity:

| String Key | Default (en) | Context |
|-----------|-------------|---------|
| (none — hardcoded literal) | `No AI provider is configured.` | The tool-calling chat session's turn-failed message when no plugin can be resolved |
| (none — hardcoded literal) | `Unknown tool: <name>` | The MCP tool source's error text when no pair matches the namespaced tool name |
| (none — hardcoded literal) | `Tool error: <description>` | The MCP tool source's error text when the underlying MCP call throws |

