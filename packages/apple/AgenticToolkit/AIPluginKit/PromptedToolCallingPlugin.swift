import Foundation

/// Gives tools to a plugin whose provider has no tool calling of its own — or
/// whose plugin does not send `AIChatContext.tools` to it, which today is all
/// of them.
///
/// It describes the tools in the system prompt and asks for each call as a
/// `<tool_call>` block of JSON in the reply text. The decoder holds the reply
/// back until it ends, lifts those blocks out as `.toolUse` events, and passes
/// the rest on as text. Earlier calls and their results are written back into
/// the conversation as text the same way, so the history reads as one protocol.
///
/// Holding the reply back costs streaming, which is why this is opt-in for the
/// caller that needs tools rather than applied to every plugin. A context with
/// no tools passes through untouched.
public final class PromptedToolCallingPlugin: AIPlugin, @unchecked Sendable {

    private let wrapped: any AIPlugin

    public init(wrapping plugin: any AIPlugin) {
        self.wrapped = plugin
    }

    /// `AIPlugin` requires it, for loading a principal class from a bundle —
    /// which a wrapper never is. Built this way it wraps nothing, and every
    /// request fails saying so.
    public required init() {
        self.wrapped = NothingWrapped()
    }

    public func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec {
        guard !context.tools.isEmpty else { return try wrapped.buildRequest(context) }
        let instructions = Self.instructions(for: context.tools)
        let systemPrompt = [context.systemPrompt, instructions]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n\n")
        return try wrapped.buildRequest(AIChatContext(
            messages: Self.textual(context.messages),
            model: context.model,
            systemPrompt: systemPrompt,
            maxTokens: context.maxTokens,
            tools: [],
            // The tools described above are the only ones this turn may use.
            config: context.config.setting(AIPluginConfig.builtInToolsKey, to: "none")
        ))
    }

    public func makeDecoder() -> any AIStreamDecoder {
        PromptedToolCallDecoder(wrapping: wrapped.makeDecoder())
    }

    public func buildValidationRequest(config: AIPluginConfig) -> AIRequestSpec? {
        wrapped.buildValidationRequest(config: config)
    }

    public func describeError(status: Int, body: Data) -> String? {
        wrapped.describeError(status: status, body: body)
    }

    // MARK: - Protocol

    static let openTag = "<tool_call>"
    static let closeTag = "</tool_call>"

    static func instructions(for tools: [AIToolSpec]) -> String {
        let catalog = tools.map { tool in
            let schema = String(data: tool.parametersJSONSchema, encoding: .utf8) ?? "{}"
            return "- \(tool.name): \(tool.description)\n  Arguments (JSON Schema): \(schema)"
        }.joined(separator: "\n")
        return """
            You can call these tools:
            \(catalog)

            These are not functions you have been given natively, and you have no other way to \
            act — writing the block below is the only way to call them. Never answer as if a call \
            had been made when it has not.
            To call a tool, write a block like this on its own lines, with nothing after it:
            \(openTag){"name": "<tool name>", "arguments": {<arguments as JSON>}}\(closeTag)
            Then stop and wait: the result comes back in the next message, marked as a tool \
            result. Call only the tools listed, one block per call. When you need no more tool \
            calls, answer the user in plain text with no blocks. Never invent a tool result.
            """
    }

    /// The conversation with every tool call and result turned into the text
    /// the instructions describe — the provider has no other way to see them.
    static func textual(_ messages: [AIChatMessage]) -> [AIChatMessage] {
        var result: [AIChatMessage] = []
        for message in messages {
            switch message.role {
            case .toolUse:
                let call = block(name: message.toolName ?? "", argumentsJSON: message.toolArgumentsJSON)
                // A call follows the assistant text of the same turn, so it joins it.
                if let last = result.last, last.role == .assistant {
                    result[result.count - 1] = AIChatMessage(role: .assistant, content: last.content + "\n" + call)
                } else {
                    result.append(AIChatMessage(role: .assistant, content: call))
                }
            case .toolResult:
                let label = message.toolIsError == true ? "Tool error" : "Tool result"
                let text = "[\(label)]\n\(message.content)"
                if let last = result.last, last.role == .user {
                    result[result.count - 1] = AIChatMessage(role: .user, content: last.content + "\n\n" + text)
                } else {
                    result.append(AIChatMessage(role: .user, content: text))
                }
            default:
                result.append(message)
            }
        }
        return result
    }

    private static func block(name: String, argumentsJSON: Data?) -> String {
        let arguments = argumentsJSON.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let nameJSON = (try? JSONSerialization.data(withJSONObject: [name], options: [.fragmentsAllowed]))
            .flatMap { String(data: $0, encoding: .utf8) }
            .map { String($0.dropFirst().dropLast()) } ?? "\"\(name)\""
        return "\(openTag){\"name\": \(nameJSON), \"arguments\": \(arguments)}\(closeTag)"
    }

    /// Splits a finished reply into its prose and its tool calls. A block that
    /// is not valid JSON naming a tool is left in the prose, so the user sees
    /// what the model wrote rather than losing it.
    static func parse(_ reply: String) -> (text: String, calls: [(name: String, argumentsJSON: Data)]) {
        var text = ""
        var calls: [(name: String, argumentsJSON: Data)] = []
        var rest = Substring(reply)
        while let open = rest.range(of: openTag) {
            text += rest[..<open.lowerBound]
            guard let close = rest.range(of: closeTag, range: open.upperBound..<rest.endIndex) else {
                text += rest[open.lowerBound...]
                rest = ""
                break
            }
            let body = rest[open.upperBound..<close.lowerBound]
            if let object = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any],
               let name = object["name"] as? String, !name.isEmpty {
                let arguments = object["arguments"] ?? [String: Any]()
                let data = (try? JSONSerialization.data(withJSONObject: arguments, options: [.fragmentsAllowed]))
                    ?? Data("{}".utf8)
                calls.append((name, data))
            } else {
                text += rest[open.lowerBound..<close.upperBound]
            }
            rest = rest[close.upperBound...]
        }
        text += rest
        return (text.trimmingCharacters(in: .whitespacesAndNewlines), calls)
    }
}

/// Holds the wrapped decoder's text until the reply ends, then answers it as
/// prose plus `.toolUse` events.
final class PromptedToolCallDecoder: AIStreamDecoder {

    private let wrapped: any AIStreamDecoder
    private var reply = ""
    private var callCount = 0
    private var flushed = false

    init(wrapping decoder: any AIStreamDecoder) {
        self.wrapped = decoder
    }

    func consume(_ data: Data) -> [AIStreamEvent] {
        absorb(wrapped.consume(data))
    }

    func finish() -> [AIStreamEvent] {
        var events = absorb(wrapped.finish())
        if !flushed { events += flush(stopReason: nil) }
        return events
    }

    private func absorb(_ events: [AIStreamEvent]) -> [AIStreamEvent] {
        var out: [AIStreamEvent] = []
        for event in events {
            switch event {
            case .textDelta(let text):
                reply += text
            case .toolUse:
                // A provider that does call tools natively still gets through.
                out.append(event)
            case .end(let stopReason):
                if !flushed { out += flush(stopReason: stopReason) }
            }
        }
        return out
    }

    private func flush(stopReason: String?) -> [AIStreamEvent] {
        flushed = true
        let (text, calls) = PromptedToolCallingPlugin.parse(reply)
        var events: [AIStreamEvent] = []
        if !text.isEmpty { events.append(.textDelta(text)) }
        for call in calls {
            callCount += 1
            events.append(.toolUse(id: "prompted-\(callCount)", name: call.name, argumentsJSON: call.argumentsJSON))
        }
        events.append(.end(stopReason: calls.isEmpty ? stopReason : "tool_use"))
        return events
    }
}

/// What a `PromptedToolCallingPlugin` made without a plugin wraps.
private final class NothingWrapped: AIPlugin, @unchecked Sendable {
    struct NoPlugin: Error, LocalizedError {
        var errorDescription: String? { "PromptedToolCallingPlugin was created without a plugin to wrap." }
    }
    func buildRequest(_ context: AIChatContext) throws -> AIRequestSpec { throw NoPlugin() }
    func makeDecoder() -> any AIStreamDecoder { NothingDecoded() }
}

private final class NothingDecoded: AIStreamDecoder {
    func consume(_ data: Data) -> [AIStreamEvent] { [] }
}
