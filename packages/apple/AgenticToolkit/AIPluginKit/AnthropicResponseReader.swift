import Foundation

/// Passive reader of an Anthropic response (SSE or JSON) for the record.
/// Never alters bytes, never throws, tolerates arbitrary chunking.
/// Not thread-safe; one per response.
public final class AnthropicResponseReader {
    /// JSON bodies larger than this are not buffered; every field stays nil.
    static let jsonLimit = 4 * 1024 * 1024

    private let streaming: Bool
    private var buffer = Data()
    private var overflowed = false

    public private(set) var model: String?
    public private(set) var inputTokens: Int?
    public private(set) var outputTokens: Int?
    public private(set) var cacheReadTokens: Int?
    public private(set) var cacheCreationTokens: Int?
    public private(set) var stopReason: String?

    public init(streaming: Bool) {
        self.streaming = streaming
    }

    public func consume(_ chunk: Data) {
        if streaming {
            buffer.append(chunk)
            while let newline = buffer.firstIndex(of: 0x0A) {
                var line = buffer[buffer.startIndex..<newline]
                buffer.removeSubrange(buffer.startIndex...newline)
                if line.last == 0x0D { line = line.dropLast() }
                handle(line: Data(line))
            }
            // A line with no newline for this long is not an event we need.
            if buffer.count > Self.jsonLimit { buffer = Data() }
        } else if !overflowed {
            if buffer.count + chunk.count > Self.jsonLimit {
                overflowed = true
                buffer = Data()
            } else {
                buffer.append(chunk)
            }
        }
    }

    public func finish() {
        if streaming {
            if !buffer.isEmpty {
                let line = buffer
                buffer = Data()
                handle(line: line)
            }
        } else if !overflowed, !buffer.isEmpty {
            if let root = (try? JSONSerialization.jsonObject(with: buffer)) as? [String: Any] {
                model = root["model"] as? String
                stopReason = root["stop_reason"] as? String
                applyUsage(root["usage"] as? [String: Any])
            }
            buffer = Data()
        }
    }

    private func handle(line: Data) {
        guard let text = String(data: line, encoding: .utf8), text.hasPrefix("data:") else { return }
        var payload = text.dropFirst(5)
        if payload.hasPrefix(" ") { payload = payload.dropFirst() }
        guard let root = (try? JSONSerialization.jsonObject(with: Data(payload.utf8))) as? [String: Any] else {
            return
        }
        switch root["type"] as? String {
        case "message_start":
            if let message = root["message"] as? [String: Any] {
                if let value = message["model"] as? String { model = value }
                applyUsage(message["usage"] as? [String: Any])
            }
        case "message_delta":
            if let delta = root["delta"] as? [String: Any], let reason = delta["stop_reason"] as? String {
                stopReason = reason
            }
            applyUsage(root["usage"] as? [String: Any])
        default: break
        }
    }

    private func applyUsage(_ usage: [String: Any]?) {
        guard let usage else { return }
        if let value = usage["input_tokens"] as? Int { inputTokens = value }
        if let value = usage["output_tokens"] as? Int { outputTokens = value }
        if let value = usage["cache_read_input_tokens"] as? Int { cacheReadTokens = value }
        if let value = usage["cache_creation_input_tokens"] as? Int { cacheCreationTokens = value }
    }
}
