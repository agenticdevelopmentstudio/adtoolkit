import Foundation
import Combine

/// What the Automation settings panel shows about the MCP endpoint: filled
/// by the host's automation feature when it starts, read by the panel.
@MainActor
public final class AutomationServerStatus: ObservableObject {
    /// The port actually listening; nil until started, or when it failed.
    @Published public var port: UInt16?
    /// The bearer token, for the registration command.
    @Published public var token: String?
    /// Whether `~/.claude.json` lists this server on this port.
    @Published public var isRegistered = false
    /// Why the endpoint is not running, when it is not.
    @Published public var failureReason: String?

    public init() {}

    /// The URL a caller posts to, once there is a port.
    public var url: String? {
        port.map { "http://127.0.0.1:\($0)\(MCPHTTPEndpoint.path)" }
    }

    /// One sentence for the panel.
    public var line: String {
        Self.line(port: port, isRegistered: isRegistered, failureReason: failureReason)
    }

    /// The sentence for these values. The panel renders from the values a
    /// `@Published` property publishes, which arrive before the property
    /// itself changes, so the sentence cannot be read back off `self` there.
    public static func line(port: UInt16?, isRegistered: Bool, failureReason: String?) -> String {
        if let failureReason { return "Not running: \(failureReason)" }
        guard let port else { return "Starting." }
        return "Listening on port \(port). \(isRegistered ? "Registered" : "Not registered") with Claude Code."
    }
}
