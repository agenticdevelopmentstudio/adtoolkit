import Foundation

/// How a Claude Code install learns about the endpoint: one `claude mcp add`
/// the user runs once, with the URL and token written as shell defaults so
/// a shell inside the app (where the variables are set) wins over the
/// values baked in at registration time.
public enum MCPRegistration {

    public static let serverName = "adkitchen"

    public static func claudeCommand(port: UInt16, token: String) -> String {
        let url = "http://127.0.0.1:\(port)\(MCPHTTPEndpoint.path)"
        return "claude mcp add --transport http --scope user \(serverName) "
            + "'${ADKITCHEN_MCP_URL:-\(url)}' "
            + "--header 'Authorization: Bearer ${ADKITCHEN_MCP_TOKEN:-\(token)}' "
            + "--header '\(HostMCPServer.callerHeader): ${ADKITCHEN_PANE_ID:-}'"
    }

    /// Whether `claudeConfig` (normally `~/.claude.json`) has an `mcpServers`
    /// entry named `serverName` whose URL names `port` — literally, or as the
    /// `${ADKITCHEN_MCP_URL:-…}` default the command above writes.
    public static func isRegistered(claudeConfig: URL, port: UInt16) -> Bool {
        guard let data = try? Data(contentsOf: claudeConfig),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let servers = root["mcpServers"] as? [String: Any],
              let entry = servers[serverName] as? [String: Any],
              let url = entry["url"] as? String else { return false }
        return url.contains("127.0.0.1:\(port)\(MCPHTTPEndpoint.path)")
    }
}
