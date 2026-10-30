import Foundation

/// One decoded line of `claude -p --output-format stream-json`.
public struct ClaudeStreamMessage: Sendable, Equatable {
    public enum Kind: Sendable, Equatable { case systemInit, assistant, user, result, other(String) }

    public struct Block: Sendable, Equatable {
        public enum Kind: Sendable, Equatable { case text, toolUse, toolResult, thinking, other }
        public var kind: Kind
        public var text: String?
        public var name: String?
        public var id: String?
        public var toolUseID: String?

        public init(kind: Kind, text: String? = nil, name: String? = nil, id: String? = nil,
                    toolUseID: String? = nil) {
            self.kind = kind
            self.text = text
            self.name = name
            self.id = id
            self.toolUseID = toolUseID
        }
    }

    public var kind: Kind
    public var subtype: String?
    public var sessionID: String?
    public var blocks: [Block]
    public var isError: Bool
    public var resultText: String?

    public init(kind: Kind, subtype: String? = nil, sessionID: String? = nil, blocks: [Block] = [],
                isError: Bool = false, resultText: String? = nil) {
        self.kind = kind
        self.subtype = subtype
        self.sessionID = sessionID
        self.blocks = blocks
        self.isError = isError
        self.resultText = resultText
    }

    /// Decodes one line. Throws `DecodingError` when the line is not a JSON object.
    public static func decode(_ line: Data) throws -> ClaudeStreamMessage {
        let any: Any
        do { any = try JSONSerialization.jsonObject(with: line) } catch {
            throw DecodingError.dataCorrupted(
                .init(codingPath: [], debugDescription: "not JSON", underlyingError: error))
        }
        guard let obj = any as? [String: Any] else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "not a JSON object"))
        }
        let type = obj["type"] as? String ?? ""
        let subtype = obj["subtype"] as? String
        let kind: Kind
        switch type {
        case "system" where subtype == "init": kind = .systemInit
        case "assistant": kind = .assistant
        case "user": kind = .user
        case "result": kind = .result
        default: kind = .other(type)
        }
        var blocks: [Block] = []
        if let message = obj["message"] as? [String: Any] {
            if let content = message["content"] as? [[String: Any]] {
                blocks = content.map(block(from:))
            } else if let text = message["content"] as? String {
                blocks = [Block(kind: .text, text: text)]
            }
        }
        return ClaudeStreamMessage(kind: kind, subtype: subtype, sessionID: obj["session_id"] as? String,
                                   blocks: blocks, isError: obj["is_error"] as? Bool ?? false,
                                   resultText: obj["result"] as? String)
    }

    private static func block(from raw: [String: Any]) -> Block {
        switch raw["type"] as? String {
        case "text": return Block(kind: .text, text: raw["text"] as? String)
        case "thinking": return Block(kind: .thinking, text: raw["thinking"] as? String)
        case "tool_use": return Block(kind: .toolUse, name: raw["name"] as? String, id: raw["id"] as? String)
        case "tool_result":
            var text = raw["content"] as? String
            if text == nil, let parts = raw["content"] as? [[String: Any]] {
                text = parts.compactMap { $0["text"] as? String }.joined(separator: "\n")
            }
            return Block(kind: .toolResult, text: text, toolUseID: raw["tool_use_id"] as? String)
        default: return Block(kind: .other)
        }
    }
}

/// The line the app writes to claude's stdin.
public enum ClaudeStreamInput {
    public static func userMessage(_ text: String) -> Data {
        let obj: [String: Any] = [
            "type": "user",
            "message": ["role": "user", "content": [["type": "text", "text": text]]]
        ]
        guard var data = try? JSONSerialization.data(withJSONObject: obj, options: [.withoutEscapingSlashes]) else {
            preconditionFailure("a user message is plain strings and always serializes")
        }
        data.append(0x0A)
        return data
    }
}
