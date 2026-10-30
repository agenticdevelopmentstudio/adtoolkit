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
        guard let data = try? JSONSerialization.data(withJSONObject: root, options: options) else {
            preconditionFailure("MCP config is plain strings and always serializes")
        }
        return data
    }

    /// The file carries the bearer token, so it is never readable by others at any moment: the parent is
    /// 0700, and the data goes into a sibling temp file created 0600 (`O_EXCL`) and is renamed over the target.
    public static func write(port: UInt16, token: String, callerID: String, to url: URL) throws {
        let files = FileManager.default
        let directory = url.deletingLastPathComponent()
        try files.createDirectory(at: directory, withIntermediateDirectories: true,
                                  attributes: [.posixPermissions: 0o700])
        try files.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
        let temp = directory.appendingPathComponent(".\(url.lastPathComponent).\(UUID().uuidString).tmp")
        let descriptor = open(temp.path, O_CREAT | O_EXCL | O_WRONLY, 0o600)
        guard descriptor >= 0 else { throw CocoaError(.fileWriteNoPermission) }
        let handle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: true)
        do {
            try handle.write(contentsOf: json(port: port, token: token, callerID: callerID))
            try handle.close()
            if rename(temp.path, url.path) != 0 { throw CocoaError(.fileWriteUnknown) }
        } catch {
            try? files.removeItem(at: temp)
            throw error
        }
    }
}
