import Foundation

/// Wire-format translation between the Anthropic Messages API and OpenAI
/// Chat Completions. Pass-through dictionaries via `JSONSerialization`; only
/// structural failure throws, unknown content blocks are dropped.
public enum AnthropicChatTranslation {
    public enum TranslationError: Error, Equatable {
        case notAnObject
        case noMessages
        case malformedReply
    }

    // MARK: - Request

    /// Anthropic Messages request body -> Chat Completions request body.
    public static func chatRequest(
        fromMessages body: Data,
        model: String,
        maxTokensKey: String = "max_tokens"
    ) throws -> Data {
        guard let root = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] else {
            throw TranslationError.notAnObject
        }
        guard let messages = root["messages"] as? [[String: Any]], !messages.isEmpty else {
            throw TranslationError.noMessages
        }

        var out: [String: Any] = ["model": model]
        var chatMessages: [[String: Any]] = []

        if let system = joinedText(root["system"]), !system.isEmpty {
            chatMessages.append(["role": "system", "content": system])
        }
        for message in messages {
            let role = message["role"] as? String ?? "user"
            if role == "assistant" {
                chatMessages.append(assistantMessage(message["content"]))
            } else {
                chatMessages.append(contentsOf: userMessages(message["content"]))
            }
        }
        out["messages"] = chatMessages

        if let tools = root["tools"] as? [[String: Any]] {
            let converted: [[String: Any]] = tools.compactMap { tool in
                guard let schema = tool["input_schema"], let name = tool["name"] as? String else { return nil }
                var function: [String: Any] = ["name": name, "parameters": schema]
                if let description = tool["description"] as? String { function["description"] = description }
                return ["type": "function", "function": function]
            }
            if !converted.isEmpty { out["tools"] = converted }
        }
        if let choice = root["tool_choice"] as? [String: Any], let type = choice["type"] as? String {
            switch type {
            case "auto": out["tool_choice"] = "auto"
            case "any": out["tool_choice"] = "required"
            case "none": out["tool_choice"] = "none"
            case "tool":
                if let name = choice["name"] as? String {
                    out["tool_choice"] = ["type": "function", "function": ["name": name]]
                }
            default: break
            }
        }
        if let stop = root["stop_sequences"] { out["stop"] = stop }
        if let temperature = root["temperature"] { out["temperature"] = temperature }
        if let topP = root["top_p"] { out["top_p"] = topP }
        if let maxTokens = root["max_tokens"] { out[maxTokensKey] = maxTokens }
        if (root["stream"] as? Bool) == true {
            out["stream"] = true
            out["stream_options"] = ["include_usage": true]
        }
        return try JSONSerialization.data(withJSONObject: out)
    }

    /// Text of a string, or the "\n\n"-joined text blocks of an array.
    private static func joinedText(_ content: Any?, inToolResult: Bool = false) -> String? {
        if let string = content as? String { return string }
        guard let blocks = content as? [[String: Any]] else { return nil }
        return blocks.compactMap { block -> String? in
            switch block["type"] as? String {
            case "text": return block["text"] as? String
            case "image": return inToolResult ? "[image omitted]" : nil
            default: return nil
            }
        }.joined(separator: "\n\n")
    }

    private static func userMessages(_ content: Any?) -> [[String: Any]] {
        if let string = content as? String { return [["role": "user", "content": string]] }
        guard let blocks = content as? [[String: Any]] else { return [["role": "user", "content": ""]] }
        var toolMessages: [[String: Any]] = []
        var parts: [[String: Any]] = []
        var hasImage = false
        for block in blocks {
            switch block["type"] as? String {
            case "text":
                if let text = block["text"] as? String { parts.append(["type": "text", "text": text]) }
            case "image":
                guard let source = block["source"] as? [String: Any] else { continue }
                var url: String?
                if (source["type"] as? String) == "base64",
                   let media = source["media_type"] as? String, let data = source["data"] as? String {
                    url = "data:\(media);base64,\(data)"
                } else if (source["type"] as? String) == "url" {
                    url = source["url"] as? String
                }
                if let url {
                    hasImage = true
                    parts.append(["type": "image_url", "image_url": ["url": url]])
                }
            case "tool_result":
                var text = joinedText(block["content"], inToolResult: true) ?? ""
                if (block["is_error"] as? Bool) == true { text = "Error: " + text }
                toolMessages.append([
                    "role": "tool",
                    "tool_call_id": block["tool_use_id"] as? String ?? "",
                    "content": text
                ])
            default: break
            }
        }
        var result = toolMessages
        if !parts.isEmpty {
            if hasImage {
                result.append(["role": "user", "content": parts])
            } else {
                let text = parts.compactMap { $0["text"] as? String }.joined(separator: "\n\n")
                result.append(["role": "user", "content": text])
            }
        } else if toolMessages.isEmpty {
            result.append(["role": "user", "content": ""])
        }
        return result
    }

    private static func assistantMessage(_ content: Any?) -> [String: Any] {
        var message: [String: Any] = ["role": "assistant"]
        if let string = content as? String {
            message["content"] = string
            return message
        }
        var texts: [String] = []
        var calls: [[String: Any]] = []
        for block in (content as? [[String: Any]]) ?? [] {
            switch block["type"] as? String {
            case "text":
                if let text = block["text"] as? String { texts.append(text) }
            case "tool_use":
                let input = block["input"] ?? [String: Any]()
                let data = (try? JSONSerialization.data(withJSONObject: input, options: [.fragmentsAllowed]))
                    ?? Data("{}".utf8)
                calls.append([
                    "id": block["id"] as? String ?? "",
                    "type": "function",
                    "function": [
                        "name": block["name"] as? String ?? "",
                        "arguments": (String(bytes: data, encoding: .utf8) ?? "")
                    ]
                ])
            default: break
            }
        }
        message["content"] = texts.joined(separator: "\n\n")
        if texts.isEmpty && !calls.isEmpty { message["content"] = NSNull() }
        if !calls.isEmpty { message["tool_calls"] = calls }
        return message
    }

    // MARK: - Non-streamed reply

    static func stopReason(forFinish reason: String?) -> String {
        switch reason {
        case "stop": return "end_turn"
        case "length": return "max_tokens"
        case "tool_calls", "function_call": return "tool_use"
        case "content_filter": return "refusal"
        default: return "end_turn"
        }
    }

    /// Non-streamed chat.completion JSON -> Anthropic `message` JSON.
    public static func anthropicMessage(fromChatCompletion data: Data, fallbackModel: String) throws -> Data {
        guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let choice = (root["choices"] as? [[String: Any]])?.first,
              let message = choice["message"] as? [String: Any] else {
            throw TranslationError.malformedReply
        }
        var content: [[String: Any]] = []
        if let text = message["content"] as? String, !text.isEmpty {
            content.append(["type": "text", "text": text])
        }
        for call in (message["tool_calls"] as? [[String: Any]]) ?? [] {
            let function = call["function"] as? [String: Any] ?? [:]
            var input: Any = [String: Any]()
            if let args = function["arguments"] as? String,
               let parsed = try? JSONSerialization.jsonObject(with: Data(args.utf8)) as? [String: Any] {
                input = parsed
            }
            content.append([
                "type": "tool_use",
                "id": call["id"] as? String ?? "toolu_" + UUID().uuidString.replacingOccurrences(of: "-", with: ""),
                "name": function["name"] as? String ?? "",
                "input": input
            ])
        }
        let usage = root["usage"] as? [String: Any]
        let reply: [String: Any] = [
            "id": "msg_" + (root["id"] as? String ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")),
            "type": "message",
            "role": "assistant",
            "model": (root["model"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? fallbackModel,
            "content": content,
            "stop_reason": stopReason(forFinish: choice["finish_reason"] as? String),
            "stop_sequence": NSNull(),
            "usage": [
                "input_tokens": usage?["prompt_tokens"] as? Int ?? 0,
                "output_tokens": usage?["completion_tokens"] as? Int ?? 0
            ]
        ]
        return try JSONSerialization.data(withJSONObject: reply)
    }

    // MARK: - Error

    /// Chat Completions error body (any shape) -> Anthropic error JSON.
    public static func anthropicError(status: Int, body: Data) -> Data {
        var message: String?
        if let root = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] {
            if let error = root["error"] as? [String: Any] {
                message = error["message"] as? String
            } else if let error = root["error"] as? String {
                message = error
            } else {
                message = root["message"] as? String
            }
        }
        let text = message ?? String((String(bytes: body, encoding: .utf8) ?? "").prefix(500))
        let type: String
        switch status {
        case 400: type = "invalid_request_error"
        case 401: type = "authentication_error"
        case 403: type = "permission_error"
        case 404: type = "not_found_error"
        case 413: type = "request_too_large"
        case 429: type = "rate_limit_error"
        case 529: type = "overloaded_error"
        default: type = "api_error"
        }
        let object: [String: Any] = ["type": "error", "error": ["type": type, "message": text]]
        return (try? JSONSerialization.data(withJSONObject: object)) ?? Data()
    }
}

/// Stateful: Chat Completions SSE bytes in, Anthropic SSE bytes out.
/// Not thread-safe; one per response; never crosses an isolation boundary.
/// At most one content block is open at a time, as Anthropic's streaming
/// format requires; a fragment for a tool call whose block already closed
/// is dropped.
public final class ChatCompletionsStreamTranslator {
    private struct ToolCall {
        var id: String?
        var name = ""
        var blockIndex: Int?
        var closed = false
        var pendingArguments = ""
    }

    private let model: String
    private let messageID: String
    private var buffer = Data()
    private var started = false
    private var finished = false
    private var nextIndex = 0
    private var openIndex: Int?
    private var openTool: Int?
    private var calls: [Int: ToolCall] = [:]
    private var lastKeylessKey: Int?
    private var nextKeylessKey = -1
    private var stopReason: String?
    private var inputTokens = 0
    private var outputTokens = 0

    public init(
        model: String,
        messageID: String = "msg_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    ) {
        self.model = model
        self.messageID = messageID
    }

    public func consume(_ chunk: Data) -> Data {
        guard !finished else { buffer = Data(); return Data() }
        buffer.append(chunk)
        var out = Data()
        while !finished, let newline = buffer.firstIndex(of: 0x0A) {
            var line = buffer[buffer.startIndex..<newline]
            buffer.removeSubrange(buffer.startIndex...newline)
            if line.last == 0x0D { line = line.dropLast() }
            out.append(handle(line: Data(line)))
        }
        if finished { buffer = Data() }
        return out
    }

    public func finish() -> Data {
        guard !finished else { buffer = Data(); return Data() }
        var out = Data()
        // A final line with no trailing newline still counts.
        if !buffer.isEmpty {
            var line = buffer
            if line.last == 0x0D { line = line.dropLast() }
            buffer = Data()
            out.append(handle(line: line))
            if finished { return out }
        }
        finished = true
        out.append(startIfNeeded())
        out.append(closeOpenBlock())
        out.append(event("message_delta", [
            "type": "message_delta",
            "delta": ["stop_reason": stopReason ?? "end_turn", "stop_sequence": NSNull()],
            "usage": ["output_tokens": outputTokens, "input_tokens": inputTokens]
        ]))
        out.append(event("message_stop", ["type": "message_stop"]))
        return out
    }

    private func handle(line: Data) -> Data {
        guard let text = String(data: line, encoding: .utf8), text.hasPrefix("data:") else { return Data() }
        var payload = text.dropFirst(5)
        if payload.hasPrefix(" ") { payload = payload.dropFirst() }
        if payload == "[DONE]" { return finish() }
        guard let root = (try? JSONSerialization.jsonObject(with: Data(payload.utf8))) as? [String: Any] else {
            return Data()
        }
        if let error = root["error"] as? [String: Any] {
            return fail(message: error["message"] as? String)
        }
        var out = startIfNeeded()
        if let usage = root["usage"] as? [String: Any] {
            if let prompt = usage["prompt_tokens"] as? Int { inputTokens = prompt }
            if let completion = usage["completion_tokens"] as? Int { outputTokens = completion }
        }
        guard let choice = (root["choices"] as? [[String: Any]])?.first else { return out }
        if let delta = choice["delta"] as? [String: Any] {
            if let content = delta["content"] as? String, !content.isEmpty {
                out.append(textDelta(content))
            }
            for call in (delta["tool_calls"] as? [[String: Any]]) ?? [] {
                out.append(toolDelta(call))
            }
        }
        if let reason = choice["finish_reason"] as? String {
            stopReason = AnthropicChatTranslation.stopReason(forFinish: reason)
        }
        return out
    }

    /// A provider error mid-stream: close the open block, emit one Anthropic
    /// error event, and stop. No message_delta or message_stop follows.
    private func fail(message: String?) -> Data {
        finished = true
        buffer = Data()
        var out = closeOpenBlock()
        out.append(event("error", [
            "type": "error",
            "error": ["type": "api_error", "message": message ?? "provider stream error"]
        ]))
        return out
    }

    private func startIfNeeded() -> Data {
        guard !started else { return Data() }
        started = true
        return event("message_start", [
            "type": "message_start",
            "message": [
                "id": messageID, "type": "message", "role": "assistant", "model": model,
                "content": [Any](), "stop_reason": NSNull(), "stop_sequence": NSNull(),
                "usage": ["input_tokens": 0, "output_tokens": 0]
            ]
        ])
    }

    private func closeOpenBlock() -> Data {
        guard let index = openIndex else { return Data() }
        if let key = openTool { calls[key]?.closed = true }
        openIndex = nil
        openTool = nil
        return event("content_block_stop", ["type": "content_block_stop", "index": index])
    }

    private func textDelta(_ text: String) -> Data {
        var out = Data()
        if openIndex == nil || openTool != nil {
            out.append(closeOpenBlock())
            let index = nextIndex
            nextIndex += 1
            openIndex = index
            out.append(event("content_block_start", [
                "type": "content_block_start", "index": index,
                "content_block": ["type": "text", "text": ""]
            ]))
        }
        out.append(event("content_block_delta", [
            "type": "content_block_delta", "index": openIndex ?? 0,
            "delta": ["type": "text_delta", "text": text]
        ]))
        return out
    }

    /// Which tool call a fragment belongs to. With an `index` that is the key;
    /// without one, a fragment carrying a new `id` starts a new call.
    private func key(for call: [String: Any]) -> Int {
        if let index = call["index"] as? Int { return index }
        let id = call["id"] as? String
        if let last = lastKeylessKey, id == nil || id == "" || calls[last]?.id == id || calls[last]?.id == nil {
            return last
        }
        let key = nextKeylessKey
        nextKeylessKey -= 1
        lastKeylessKey = key
        return key
    }

    private func toolDelta(_ call: [String: Any]) -> Data {
        var out = Data()
        let key = key(for: call)
        let function = call["function"] as? [String: Any] ?? [:]
        var state = calls[key] ?? ToolCall()
        if state.id == nil, let id = call["id"] as? String, !id.isEmpty { state.id = id }
        if state.blockIndex == nil, state.name.isEmpty, let name = function["name"] as? String { state.name = name }
        let arguments = function["arguments"] as? String ?? ""
        calls[key] = state

        if state.closed {
            return out   // its block is closed; Anthropic cannot reopen it
        }
        if state.blockIndex == nil {
            guard state.id != nil || !state.name.isEmpty else {
                calls[key]?.pendingArguments += arguments
                return out
            }
            out.append(closeOpenBlock())
            let index = nextIndex
            nextIndex += 1
            calls[key]?.blockIndex = index
            openIndex = index
            openTool = key
            out.append(event("content_block_start", [
                "type": "content_block_start", "index": index,
                "content_block": [
                    "type": "tool_use",
                    "id": state.id ?? "toolu_" + UUID().uuidString.replacingOccurrences(of: "-", with: ""),
                    "name": state.name,
                    "input": [String: Any]()
                ]
            ]))
            let pending = state.pendingArguments + arguments
            calls[key]?.pendingArguments = ""
            out.append(argumentsDelta(pending, index: index))
        } else if let index = state.blockIndex {
            out.append(argumentsDelta(arguments, index: index))
        }
        return out
    }

    private func argumentsDelta(_ arguments: String, index: Int) -> Data {
        guard !arguments.isEmpty else { return Data() }
        return event("content_block_delta", [
            "type": "content_block_delta", "index": index,
            "delta": ["type": "input_json_delta", "partial_json": arguments]
        ])
    }

    private func event(_ name: String, _ object: [String: Any]) -> Data {
        let json = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{}".utf8)
        var data = Data("event: \(name)\ndata: ".utf8)
        data.append(json)
        data.append(Data("\n\n".utf8))
        return data
    }
}
