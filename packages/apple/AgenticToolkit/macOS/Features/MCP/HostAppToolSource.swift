// macOS/Features/MCP/HostAppToolSource.swift
import Foundation
import AgenticToolkitCore

/// The two tools every host app offers: what it is, and "open a chat window".
/// What `HostMCPServer` used to hard-code, now one source among several.
public final class HostAppToolSource: ChatToolSource, @unchecked Sendable {
    private let appName: String
    private let appVersion: String
    private let pluginNames: [String]
    private let openChatWindow: @MainActor @Sendable () -> Void

    public init(appName: String, appVersion: String, pluginNames: [String] = [],
                openChatWindow: @escaping @MainActor @Sendable () -> Void = {}) {
        self.appName = appName; self.appVersion = appVersion
        self.pluginNames = pluginNames; self.openChatWindow = openChatWindow
    }

    public func toolDefinitions() async -> [ToolDefinition] {
        let empty = ToolJSONSchema.object(properties: [:])
        return [
            ToolDefinition(name: "host_app_info",
                           description: "Returns the host app's name, version and loaded plugins.",
                           parametersJSONSchema: empty),
            ToolDefinition(name: "host_open_chat_window",
                           description: "Opens a new AI chat window in the host app.",
                           parametersJSONSchema: empty)
        ]
    }

    public func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        switch name {
        case "host_app_info":
            return ("Host: \(appName)\nVersion: \(appVersion)\nPlugins: \(pluginNames.joined(separator: ", "))", false)
        case "host_open_chat_window":
            await openChatWindow()
            return ("Opened a new chat window.", false)
        default:
            return ("unknown tool \(name)", true)
        }
    }
}
