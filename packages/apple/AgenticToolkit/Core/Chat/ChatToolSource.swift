// Core/Chat/ChatToolSource.swift
import Foundation

/// Supplies tools to a chat engine and executes tool calls. Lets an engine
/// (e.g. `LocalChatSession`) run a tool loop without depending on MCP directly —
/// the MCP-backed implementation lives in the macOS module.
///
/// A conformer MUST implement at least one of the two `callTool` methods: the
/// defaults forward to each other, so implementing neither recurses forever.
public protocol ChatToolSource: Sendable {
    /// Tool definitions to advertise to the model for this turn.
    func toolDefinitions() async -> [ToolDefinition]
    /// Execute a tool call the model requested. Returns the result text and
    /// whether it was an error.
    func callTool(name: String, argumentsJSON: Data) async -> (content: String, isError: Bool)
    /// The same, naming who asked: the pane id of the chat or terminal the
    /// call came from, when known. Tools that pick a target by proximity
    /// (the browser tools) use it; others ignore it.
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool)
}

public extension ChatToolSource {
    func callTool(name: String, argumentsJSON: Data) async -> (content: String, isError: Bool) {
        await callTool(name: name, argumentsJSON: argumentsJSON, caller: nil)
    }
    func callTool(name: String, argumentsJSON: Data, caller: String?) async -> (content: String, isError: Bool) {
        await callTool(name: name, argumentsJSON: argumentsJSON)
    }
}
