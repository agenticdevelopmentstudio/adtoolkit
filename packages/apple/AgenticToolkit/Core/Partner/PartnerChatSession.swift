import Foundation

/// A `ChatSession` over the partner process. It does not own the process: the
/// controller feeds it decoded messages (`apply`) and the owner's own lines
/// (`noteUserMessage`), and it reports what to persist.
public final class PartnerChatSession: ChatSession, @unchecked Sendable {
    private let sendHandler: @Sendable (String) -> Void
    private let interruptHandler: @Sendable () -> Void

    private let lock = NSLock()
    private var transcript: [ChatMessage]
    private var continuation: AsyncStream<ChatEvent>.Continuation?
    private var toolNames: [String: String] = [:]
    private var currentAssistantID: ChatMessage.ID?

    public init(initial: [ChatMessage], send: @escaping @Sendable (String) -> Void,
                interrupt: @escaping @Sendable () -> Void) {
        transcript = initial
        sendHandler = send
        interruptHandler = interrupt
    }

    public func events() -> AsyncStream<ChatEvent> {
        AsyncStream { continuation in
            let initial = withLock { () -> [ChatMessage] in
                self.continuation = continuation
                return transcript
            }
            continuation.yield(.transcriptLoaded(initial))
        }
    }

    public func send(_ text: String) { sendHandler(text) }
    public func interrupt() { interruptHandler() }

    public func close() {
        let cont = withLock { () -> AsyncStream<ChatEvent>.Continuation? in
            defer { continuation = nil }
            return continuation
        }
        cont?.yield(.stateChanged(.closed))
        cont?.finish()
    }

    public func noteUserMessage(_ message: ChatMessage) {
        withLock { transcript.append(message) }
        emit(.userMessage(message))
    }

    public func setState(_ state: ChatSessionState) { emit(.stateChanged(state)) }

    public func apply(_ message: ClaudeStreamMessage) -> [ChatMessage] {
        switch message.kind {
        case .assistant: return applyAssistant(message)
        case .user:
            for block in message.blocks where block.kind == .toolResult {
                let name = block.toolUseID.flatMap { id in withLock { toolNames[id] } } ?? "tool"
                emit(.toolCall(messageID: currentOrFreshID(), name: name, phase: .completed))
            }
            return []
        case .result:
            withLock { currentAssistantID = nil }
            if message.isError {
                let text = message.resultText ?? message.subtype ?? "error"
                emit(.turnFailed(ChatError(message: text, isRetryable: true)))
            }
            emit(.stateChanged(.ready))
            return []
        case .systemInit, .other: return []
        }
    }

    private func applyAssistant(_ message: ClaudeStreamMessage) -> [ChatMessage] {
        var persisted: [ChatMessage] = []
        for block in message.blocks {
            switch block.kind {
            case .text:
                guard let text = block.text, !text.isEmpty else { continue }
                let reply = ChatMessage(role: .assistant, text: text)
                withLock { transcript.append(reply); currentAssistantID = reply.id }
                emit(.responseStarted(messageID: reply.id))
                emit(.responseDelta(messageID: reply.id, text: text))
                emit(.responseFinished(messageID: reply.id, stopReason: nil))
                persisted.append(reply)
            case .toolUse:
                if let id = block.id, let name = block.name { withLock { toolNames[id] = name } }
                emit(.toolCall(messageID: currentOrFreshID(), name: block.name ?? "tool", phase: .started))
            default: continue
            }
        }
        return persisted
    }

    private func currentOrFreshID() -> ChatMessage.ID {
        withLock {
            if let currentAssistantID { return currentAssistantID }
            let fresh = UUID().uuidString
            currentAssistantID = fresh
            return fresh
        }
    }

    private func emit(_ event: ChatEvent) {
        withLock { continuation }?.yield(event)
    }

    private func withLock<Value>(_ body: () -> Value) -> Value {
        lock.lock(); defer { lock.unlock() }; return body()
    }
}
