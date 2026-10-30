import Foundation

/// The `--mcp-config` file that points the partner's claude at the app's MCP endpoint.
public enum PartnerMCPConfig {
    public static let serverName = "adkitchen"
    public static let callerHeader = "X-ADKitchen-Pane"

    public static func json(port: UInt16, token: String, callerID: String) -> Data {
        let server: [String: Any] = [
            "type": "http",
            "url": "http://127.0.0.1:\(port)/mcp",
            "headers": ["Authorization": "Bearer \(token)", callerHeader: callerID]
        ]
        let root: [String: Any] = ["mcpServers": [serverName: server]]
        let options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes]
        return (try? JSONSerialization.data(withJSONObject: root, options: options)) ?? Data()
    }

    /// Writes atomically, then restricts to the owner: the file carries the bearer token.
    public static func write(port: UInt16, token: String, callerID: String, to url: URL) throws {
        let files = FileManager.default
        try files.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try json(port: port, token: token, callerID: callerID).write(to: url, options: .atomic)
        try files.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
}
