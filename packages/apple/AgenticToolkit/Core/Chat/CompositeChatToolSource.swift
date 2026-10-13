// Core/Chat/CompositeChatToolSource.swift
import Foundation

/// Several tool sources presented as one: definitions concatenated in order,
/// calls routed to whichever source advertises the name.
public final class CompositeChatToolSource: ChatToolSource, @unchecked Sendable {
    private let sources: [any ChatToolSource]

    public init(_ sources: [any ChatToolSource]) { self.sources = sources }

    public func toolDefinitions() async -> [ToolDefinition] {
        var out: [ToolDefinition] = []
        for source in sources { out += await source.toolDefinitions() }
        return out
    }

    public func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        for source in sources where await source.toolDefinitions().contains(where: { $0.name == name }) {
            return await source.callTool(name: name, argumentsJSON: argumentsJSON, caller: caller)
        }
        return ("unknown tool \(name)", true)
    }
}
